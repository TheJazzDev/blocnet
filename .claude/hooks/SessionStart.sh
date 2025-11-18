#!/bin/bash
# Claude Code SessionStart Hook for blocnet Flutter Project
# This hook ensures the Flutter environment is ready for development

set -e

echo "🚀 Initializing blocnet development environment..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter is not installed or not in PATH"
    echo "   Please ensure Flutter is installed: https://docs.flutter.dev/get-started/install"
    exit 0
fi

# Get Flutter version
echo "📱 Flutter version:"
flutter --version | head -n 1

# Check if dependencies are installed
if [ ! -d ".dart_tool" ] || [ ! -f ".flutter-plugins" ]; then
    echo "📦 Installing Flutter dependencies..."
    flutter pub get
else
    echo "✅ Flutter dependencies already installed"
fi

# Run flutter doctor to check setup
echo ""
echo "🏥 Checking Flutter environment:"
flutter doctor --no-version-check

echo ""
echo "✨ Environment ready! You can now use Claude Code with your Flutter project."
