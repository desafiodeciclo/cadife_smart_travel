#!/bin/bash
# Build Release Script for Cadife Smart Travel
# Usage: ./scripts/build_release.sh [apk|appbundle|ios]

set -e

BUILD_TARGET="${1:-apk}"
SYMBOLS_DIR="symbols"

mkdir -p "$SYMBOLS_DIR"

echo "🔒 Building release with obfuscation..."
echo "Target: $BUILD_TARGET"
echo "Symbols: $SYMBOLS_DIR"

flutter build "$BUILD_TARGET" \
  --release \
  --obfuscate \
  --split-debug-info="$SYMBOLS_DIR" \
  --dart-define=dart.vm.product=true

echo "✅ Build completed."
echo "📦 Output: build/app/outputs/$BUILD_TARGET/release/"
echo "🔑 Debug symbols saved to: $SYMBOLS_DIR/"
echo ""
echo "IMPORTANT: Store debug symbols securely for future crash symbolication."
