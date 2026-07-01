#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="giavascript"
SHORTCUT_NAME="gs"
BUILD_OUTPUT="$PROJECT_ROOT/bin/$BINARY_NAME"

# Default install directory can be overridden:
#   INSTALL_DIR="$HOME/.local/bin" ./install.sh
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
TARGET_PATH="$INSTALL_DIR/$BINARY_NAME"

if ! command -v crystal >/dev/null 2>&1; then
  printf "Error: Crystal is not installed or not in PATH.\n" >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/bin"

printf "Building %s with Crystal release optimizations...\n" "$BINARY_NAME"
crystal build "$PROJECT_ROOT/src/giavascript_cli.cr" \
  --release \
  --no-debug \
  -o "$BUILD_OUTPUT"

if command -v strip >/dev/null 2>&1; then
  strip "$BUILD_OUTPUT" || true
fi

if [ ! -d "$INSTALL_DIR" ]; then
  mkdir -p "$INSTALL_DIR"
fi

if [ ! -w "$INSTALL_DIR" ]; then
  printf "No write access to %s. Trying with sudo...\n" "$INSTALL_DIR"
  sudo install -m 755 "$BUILD_OUTPUT" "$TARGET_PATH"
  sudo ln -sf "$TARGET_PATH" "$INSTALL_DIR/$SHORTCUT_NAME"
else
  install -m 755 "$BUILD_OUTPUT" "$TARGET_PATH"
  ln -sf "$TARGET_PATH" "$INSTALL_DIR/$SHORTCUT_NAME"
fi

printf "Installed to %s\n" "$TARGET_PATH"
printf "Shortcut: %s -> %s\n" "$SHORTCUT_NAME" "$BINARY_NAME"

if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
  printf "Warning: '%s' is not currently in your PATH.\n" "$INSTALL_DIR" >&2
  printf "Add this to your shell config:\n" >&2
  printf "  export PATH=\"%s:\$PATH\"\n" "$INSTALL_DIR" >&2
fi

printf "Done. Run:\n"
printf "  %s\n" "$SHORTCUT_NAME"
printf "  %s path/to/file.js\n" "$SHORTCUT_NAME"
