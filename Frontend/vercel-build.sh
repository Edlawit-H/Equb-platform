#!/bin/bash
set -e

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
else
  echo "Using cached Flutter SDK"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run