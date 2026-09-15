#!/usr/bin/env bash
set -euo pipefail

OWNER="A-why"
REPO="CausalWAM-Cosmos-Cosmos"
TAG="portable-v1"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

mkdir -p .release_parts

echo "==> Downloading portable release..."

while read -r HASH FILE; do
    OUT=".release_parts/${FILE}"

    if [ -f "$OUT" ]; then
        if echo "${HASH}  ${OUT}" | sha256sum -c - >/dev/null 2>&1; then
            echo "[OK] $FILE already downloaded"
            continue
        fi
    fi

    URL="https://github.com/${OWNER}/${REPO}/releases/download/${TAG}/${FILE}"

    echo "Downloading $FILE"

    if command -v curl >/dev/null 2>&1; then
        curl -fL \
            --retry 10 \
            --retry-delay 5 \
            --retry-all-errors \
            -C - \
            -o "$OUT" \
            "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -c -O "$OUT" "$URL"
    else
        echo "ERROR: curl or wget is required."
        exit 1
    fi
done < PARTS_SHA256SUMS

echo "==> Verifying all parts..."

(
    cd .release_parts
    sha256sum -c ../PARTS_SHA256SUMS
)

echo "==> Joining archive..."

rm -f CausalWAM-Cosmos-Cosmos.tar.zst

while read -r HASH FILE; do
    cat ".release_parts/${FILE}" >> CausalWAM-Cosmos-Cosmos.tar.zst
done < PARTS_SHA256SUMS

echo "==> Verifying full archive..."

sha256sum -c FULL_ARCHIVE_SHA256

echo "==> Testing zstd archive..."

zstd -t CausalWAM-Cosmos-Cosmos.tar.zst

echo "==> Extracting release..."

tar \
  --use-compress-program=zstd \
  -xf CausalWAM-Cosmos-Cosmos.tar.zst \
  --strip-components=1 \
  -C "$ROOT"

echo
echo "=============================================="
echo " CausalWAM-Cosmos-Cosmos download complete"
echo "=============================================="
echo
echo "Next:"
echo "  bash env/unpack_portable_env.sh"
echo "  source scripts/activate_env.sh"
echo "  bash scripts/preflight.sh"
