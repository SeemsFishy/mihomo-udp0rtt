# mihomo-udp0rtt

[MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) with Hysteria2 UDP 0-RTT.

`SeemsFishy/mihomo` is already a different project, so this repository is not a GitHub fork. Actions checks out a MetaCubeX tag and applies `patches/` on top. The patch matches sing-quic `1c242664697a`, which is what mihomo v1.19.33 uses.

`udp-0rtt` defaults to on, including Salamander and Gecko. UDP leaves as soon as QUIC can carry it. On a resumed session that is real 0-RTT. The Hysteria auth POST waits until the handshake finishes. `udp-0rtt: false` keeps the original handshake.

## Workflows

- `.github/workflows/ghcr-arm64.yml` pushes `ghcr.io/seemsfishy/mihomo-udp0rtt:<tag>-udp0rtt` for `linux/arm64`.
- `.github/workflows/linux-amd64.yml` builds a static `mihomo-linux-amd64` and attaches it to a release named `<tag>-udp0rtt`.

Run either workflow and set `upstream` to a tag such as `v1.19.33`. The GHCR package is private until its visibility is changed.
