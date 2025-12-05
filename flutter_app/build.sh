#!/bin/bash
set -e  # Exit on any error

echo "=== Flutter Web Build for Vercel (Release Mode) ==="

# Step 1: Install Flutter SDK if not cached
FLUTTER_DIR="/tmp/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "📥 Downloading Flutter SDK (stable channel)..."
  git clone -b stable --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "✅ Flutter SDK found in cache."
fi

# Step 2: Update PATH
export PATH="$FLUTTER_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"

# Step 3: Verify Flutter installation
echo "🔍 Flutter version:"
flutter --version

# Step 4: Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Step 5: Clean previous builds (critical for web)
echo "🧹 Cleaning previous builds..."
flutter clean

# Step 6: Get dependencies
echo "📦 Fetching Flutter dependencies..."
flutter pub get

# Step 6b: Fix SDK version constraint if needed
echo "🔧 Checking SDK version compatibility..."
if grep -q "sdk: \">=2.17.0 <3.0.0\"" pubspec.yaml; then
  echo "⚠️ Updating SDK constraint to Dart 3.x..."
  sed -i.bak 's/sdk: ">=2.17.0 <3.0.0"/sdk: "^3.0.0"/' pubspec.yaml
  rm pubspec.yaml.bak 2>/dev/null || true
  flutter pub get
fi

# Step 7: Generate localization files (CRITICAL - your app uses l10n)
echo "🌍 Generating localization files..."
flutter gen-l10n

# Step 8: Run build_runner for Freezed/JSON serialization (CRITICAL)
echo "🏗️ Running build_runner for code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

# Step 9: Build for web (optimized for production)
echo "🚀 Building Flutter web (release mode)..."
flutter build web \
  --release \
  --base-href "/" \
  --no-tree-shake-icons

# Step 10: Fix asset paths for web (CRITICAL FIX)
echo "🔧 Fixing asset paths for web deployment..."
cd build/web

# Ensure assets are accessible
if [ ! -d "assets" ]; then
  echo "⚠️ Warning: assets directory not found"
fi

# Step 11: Create .htaccess for proper routing (if needed)
cat > .htaccess << 'EOF'
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
EOF

cd ../..

# Step 12: Validate output
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
  echo "✅ Build successful! Output in build/web"
  echo "📊 Build directory contents:"
  ls -lah build/web | head -n 15
else
  echo "❌ Build failed: No valid output in build/web"
  exit 1
fi

echo "🎉 Deployment build complete!"