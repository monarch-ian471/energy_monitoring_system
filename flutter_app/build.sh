#!/bin/bash
set -e

echo "Installing Flutter SDK..."

# Download and install Flutter (stable channel)
git clone -b stable --depth 1 https://github.com/flutter/flutter.git /tmp/flutter

# Add Flutter to PATH (already done via vercel.json env)
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Verify installation
flutter --version

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for web (release mode, base-href if needed)
flutter build web --release --web-renderer canvaskit --csp

# Vercel expects output in build/web by default when distDir is set
echo "Build completed → build/web"