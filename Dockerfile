# syntax=docker/dockerfile:1
# Geo files are fetched on the build machine. The final stage is often arm64
# under QEMU, and wget there fails with "network failure" (exit 4).
FROM --platform=$BUILDPLATFORM alpine:3.22 AS geo

RUN apk add --no-cache ca-certificates wget \
 && mkdir -p /geo \
 && download() { \
      name="$1"; \
      i=0; \
      until wget -O "/geo/$name" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/$name"; do \
        i=$((i+1)); \
        if [ "$i" -ge 5 ]; then \
          echo "failed to download $name" >&2; \
          exit 1; \
        fi; \
        sleep $((i * 5)); \
      done; \
    }; \
    download geoip.metadb; \
    download geosite.dat; \
    download geoip.dat

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

FROM alpine:3.22

LABEL org.opencontainers.image.source="https://github.com/SeemsFishy/mihomo"
LABEL org.opencontainers.image.description="mihomo with Hysteria2 UDP 0-RTT"
ARG VERSION=v1.19.33-udp0rtt
LABEL org.opencontainers.image.version="${VERSION}"

RUN apk add --no-cache ca-certificates tzdata iptables \
 && mkdir -p /root/.config/mihomo

COPY --from=geo /geo/ /root/.config/mihomo/
VOLUME ["/root/.config/mihomo/"]
COPY --from=build /out/mihomo /mihomo

ENTRYPOINT ["/mihomo"]
