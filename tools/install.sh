#!/usr/bin/env sh
set -eu

REPO="marcelsud/sdl-cli"
INSTALL_DIR=${INSTALL_DIR:-/usr/local/bin}
CMD=${CMD:-sdl}

have() { command -v "$1" >/dev/null 2>&1; }

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$OS" in
  linux|darwin|windows) ;;
  *) echo "error: unsupported OS: $OS" >&2; exit 1 ;;
esac
case "$ARCH" in
  x86_64|amd64) ARCH=x86_64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "error: unsupported ARCH: $ARCH" >&2; exit 1 ;;
esac

ASSET="sdl-cli_${OS}_${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"
TMP=$(mktemp -d)
ARCHIVE="$TMP/$ASSET"
trap 'rm -rf "$TMP"' EXIT

if have curl; then
  echo "Downloading ${URL} with curl" >&2
  curl -fL "$URL" -o "$ARCHIVE"
elif have wget; then
  echo "Downloading ${URL} with wget" >&2
  wget -qO "$ARCHIVE" "$URL"
else
  echo "error: curl or wget required" >&2
  exit 1
fi

tar -C "$TMP" -xz -f "$ARCHIVE"

BIN="$TMP/sdl"
if [ ! -f "$BIN" ]; then
  echo "error: binary 'sdl' not found in archive" >&2
  exit 1
fi

install -d "$INSTALL_DIR"
install "$BIN" "$INSTALL_DIR/$CMD"
echo "Installed $CMD to $INSTALL_DIR/$CMD"
