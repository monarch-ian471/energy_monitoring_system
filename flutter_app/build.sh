#!/bin/bash
set -e  # Exit on any error for reliable builds

echo "=== Starting Flutter Web Build for Vercel ==="

# Step 1: Install Flutter SDK if not cached
FLUTTER_DIR="/tmp/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Downloading Flutter SDK (stable channel)..."
  git clone -b stable --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "Flutter SDK found in cache."
fi

# Step 2: Dynamically update PATH (this is safe in Bash—no Vercel reservation conflict)
export PATH="$FLUTTER_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"

# Step 3: Verify installation
echo "Flutter version:"
flutter --version

# Step 4: Enable web support (idempotent, safe to run multiple times)
flutter config --enable-web

# Step 5: Get dependencies
echo "Fetching Flutter dependencies..."
flutter pub get

# Step 6: Build for web (optimized for Vercel/static hosting)
echo "Building Flutter web (release mode with CanvasKit renderer for better perf)..."
flutter build web \
  --release \
#   --csp \
  --base-href "/"  # Adjust if using subpaths

# Step 7: Validate output
if [ -d "build/web" ]; then
  echo "=== Build successful! Output in build/web ==="
  ls -la build/web | head -n 10  # Quick dir listing for logs
else
  echo "Build failed: No output in build/web"
  exit 1
fi