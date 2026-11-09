#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test -f src/go.mod
modline=$(grep 'github.com/metacubex/sing-quic ' src/go.mod | grep -v '^replace' | head -1)
commit=$(printf '%s\n' "$modline" | awk '{print $2}' | awk -F- '{print $NF}')
test -n "$commit"
rm -rf src/third_party/sing-quic
git clone https://github.com/metacubex/sing-quic.git src/third_party/sing-quic
git -C src/third_party/sing-quic checkout --detach "$commit"
rm -rf src/third_party/sing-quic/.git
patch -d src/third_party/sing-quic -p1 < patches/sing-quic-hysteria2.patch
patch -d src -p1 < patches/hysteria2-outbound.patch
cp Dockerfile src/Dockerfile
if ! grep -q '=> ./third_party/sing-quic' src/go.mod; then
  printf '\nreplace github.com/metacubex/sing-quic => ./third_party/sing-quic\n' >> src/go.mod
fi
