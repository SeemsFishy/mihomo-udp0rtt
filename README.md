# mihomo-udp0rtt

[MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) with Hysteria2 UDP 0-RTT.

This is not a GitHub fork of MetaCubeX/mihomo. The name `SeemsFishy/mihomo` is already the Star Rail Mihomo API library. Actions checks out the upstream tag and applies the files in this repository on top.

`udp-0rtt` defaults to on, including Salamander and Gecko. UDP datagrams leave as soon as QUIC can carry them. On a resumed session that is real 0-RTT. The Hysteria auth POST waits until the QUIC handshake is finished, so a server that rejects 0-RTT cannot tear the connection down. `udp-0rtt: false` keeps the original wait-for-233 handshake.

## Workflows

- [GHCR arm64](.github/workflows/ghcr-arm64.yml) builds `linux/arm64` and pushes `ghcr.io/seemsfishy/mihomo-udp0rtt:<tag>-udp0rtt`.
- [linux amd64 binary](.github/workflows/linux-amd64.yml) builds a static `mihomo-linux-amd64` and attaches it to a release.

Run either workflow with the upstream tag, for example `v1.19.33`. The overlay matches that tag. A newer upstream tag needs the Hysteria2 outbound file to still line up with `overlay/adapter/outbound/hysteria2.go`.

The first GHCR package is private until you change the package visibility.
