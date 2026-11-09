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

FROM alpine:3.22

LABEL org.opencontainers.image.source="https://github.com/SeemsFishy/mihomo-udp0rtt"
LABEL org.opencontainers.image.description="mihomo with Hysteria2 UDP 0-RTT"
ARG VERSION=v1.19.33-udp0rtt
LABEL org.opencontainers.image.version="${VERSION}"

RUN apk add --no-cache ca-certificates tzdata iptables \
 && mkdir -p /root/.config/mihomo

# Filled by the workflow on the runner. Downloading these inside BuildKit
# fails: GitHub release assets stall, and arm64 QEMU makes it worse.
COPY docker/geo/ /root/.config/mihomo/
VOLUME ["/root/.config/mihomo/"]
COPY --from=build /out/mihomo /mihomo

ENTRYPOINT ["/mihomo"]
