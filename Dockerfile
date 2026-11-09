# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build

RUN apk add --no-cache git ca-certificates

WORKDIR /src

COPY go.mod go.sum ./
COPY third_party/sing-quic ./third_party/sing-quic
RUN go mod download

COPY . .

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=v1.19.33-udp0rtt

RUN set -eu; \
    BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
    CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go build -tags with_gvisor -trimpath \
      -ldflags "-s -w -buildid= -X github.com/metacubex/mihomo/constant.Version=${VERSION} -X github.com/metacubex/mihomo/constant.BuildTime=${BUILD_TIME}" \
      -o /out/mihomo .

# Fetch geo data on the build machine. The final stage runs under qemu when
# the image is arm64, and wget from there fails with exit 4.
FROM --platform=$BUILDPLATFORM alpine:3.22 AS geo

RUN apk add --no-cache ca-certificates curl \
 && mkdir -p /geo \
 && curl -fL --retry 8 --retry-all-errors --retry-delay 2 \
      -o /geo/geoip.metadb https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.metadb \
 && curl -fL --retry 8 --retry-all-errors --retry-delay 2 \
      -o /geo/geosite.dat https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat \
 && curl -fL --retry 8 --retry-all-errors --retry-delay 2 \
      -o /geo/geoip.dat https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat

FROM alpine:3.22

LABEL org.opencontainers.image.source="https://github.com/SeemsFishy/mihomo"
LABEL org.opencontainers.image.description="mihomo with Hysteria2 UDP 0-RTT"
ARG VERSION=v1.19.33-udp0rtt
LABEL org.opencontainers.image.version="${VERSION}"

RUN apk add --no-cache ca-certificates tzdata iptables

VOLUME ["/root/.config/mihomo/"]

COPY --from=geo /geo/ /root/.config/mihomo/
COPY --from=build /out/mihomo /mihomo

ENTRYPOINT ["/mihomo"]
