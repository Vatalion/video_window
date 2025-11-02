# Development Environment Setup Guide

## Overview

This guide provides comprehensive setup instructions for the Craft Video Marketplace development environment. Following these procedures ensures consistency across all development machines and enables optimal productivity.

## Prerequisites

### System Requirements
- **Operating System**: macOS 13+, Windows 11, or Ubuntu 22.04+
- **Memory**: Minimum 16GB RAM (32GB recommended for video processing)
- **Storage**: 50GB free disk space (100GB recommended)
- **Processor**: Apple Silicon (M1/M2/M3), Intel i7+, or AMD Ryzen 7+

### Required Accounts
- GitHub account with organization access
- AWS account with IAM permissions for development resources
- Google Play Console (Android deployment)
- Apple Developer Account (iOS deployment)

## Core Development Tools

### 1. Flutter SDK Installation

#### macOS (Recommended)
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install --cask flutter

# Verify installation
flutter doctor -v
```

#### Windows
```powershell
# Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
# Extract to C:\flutter
# Add to PATH: C:\flutter\bin

# Verify installation
flutter doctor -v
```

#### Ubuntu
```bash
# Download and extract Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz
tar xf flutter_linux_3.19.6-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
```

### 2. Development Environment Setup

#### Git Configuration
```bash
# Set up Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Configure default branch
git config --global init.defaultBranch develop

# Set up Git hooks
git config --global core.hooksPath .githooks
```

#### IDE Setup - VS Code (Recommended)

**Required Extensions:**
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "dart-code.debugger-dart",
    "alexisvt.flutter-snippets",
    "nash.awesome-flutter-intellisense",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-azuretools.vscode-docker",
    "hashicorp.terraform",
    "ms-vscode-remote.remote-containers"
  ]
}
```

**VS Code Settings:**
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 100,
  "editor.rulers": [100],
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "files.associations": {
    "*.arb": "json"
  }
}
```

#### IDE Setup - IntelliJ IDEA (Alternative)

**Plugins to Install:**
- Flutter
- Dart
- .env files support
- Terraform
- Docker

**Configuration:**
```json
{
  "codeStyle": {
    "dart": {
      "RIGHT_MARGIN": 100,
      "ENABLE_CLOSING_BRACES": true,
      "ENABLE_CLOSING_TAGS": true
    }
  }
}
```

### 3. Platform-Specific Setup

#### Android Development
```bash
# Install Android Studio
# macOS: brew install --cask android-studio
# Windows: Download from https://developer.android.com/studio

# Install Android SDK
flutter config --android-studio-dir /path/to/android-studio

# Accept licenses
flutter doctor --android-licenses

# Set up Android device or emulator
flutter devices
```

#### iOS Development (macOS only)
```bash
# Install Xcode from App Store
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods
pod setup

# Verify iOS setup
flutter doctor --verbose
```

## Project Initialization

### 1. Repository Cloning
```bash
# Clone the repository
git clone https://github.com/your-org/craft-video-marketplace.git
cd craft-video-marketplace

# Switch to develop branch
git checkout develop

# Install Flutter dependencies
flutter pub get

# Install Serverpod dependencies (when backend is added)
cd serverpod
dart pub get
cd ..
```

### 2. Environment Configuration
```bash
# Copy environment templates
cp .env.example .env.local
cp .env.staging.example .env.staging

# Edit local environment variables
# .env.local should contain:
# API_BASE_URL=http://localhost:8080
# FLUTTER_ENV=development
# LOG_LEVEL=debug
```

### 3. Pre-commit Hooks Setup
```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Verify hooks
pre-commit run --all-files
```

## Local Development Services

### 1. Docker Development Environment
```bash
# Install Docker Desktop
# macOS: brew install --cask docker
# Windows: Download from https://www.docker.com/products/docker-desktop

# Start development services
docker-compose -f docker-compose.dev.yml up -d

# Verify services
docker ps
```

### 2. Database Setup (Local Development)
```bash
# Start PostgreSQL container
docker run -d \
  --name craft-dev-db \
  -e POSTGRES_PASSWORD=devpassword \
  -e POSTGRES_DB=craft_dev \
  -p 5432:5432 \
  postgres:15-alpine

# Start Redis container
docker run -d \
  --name craft-dev-redis \
  -p 6379:6379 \
  redis:7-alpine
```

### 3. Backend Development Server (Serverpod)
```bash
# Navigate to serverpod directory
cd serverpod

# Start development server
dart run serverpod_cli generate
dart run bin/main.dart --mode development

# In separate terminal, run migrations
dart run serverpod_cli migrator apply
```

## Development Workflow

### 1. Running the Flutter Application
```bash
# Connect to development server
flutter run --debug --dart-define=FLUTTER_ENV=development

# Run on specific device
flutter run -d chrome --web-port=3000
flutter run -d "iPhone 15 Pro"
flutter run -d "Pixel 7 Pro"
```

### 2. Hot Reload and Hot Restart
```bash
# Hot reload (preserves state)
# Press 'r' in terminal or use IDE hot reload

# Hot restart (resets state)
# Press 'R' in terminal or use IDE hot restart
```

### 3. Debugging Configuration
```json
{
  "type": "dart",
  "request": "launch",
  "name": "craft_marketplace",
  "program": "lib/main.dart",
  "args": ["--dart-define=FLUTTER_ENV=development"],
  "env": {
    "FLUTTER_WEB_USE_SKIA": "true"
  }
}
```

## Development Tools and Scripts

### 1. Setup Automation Script
Create `scripts/setup-dev.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Setting up Craft Video Marketplace Development Environment"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Setup pre-commit hooks
echo "🔧 Setting up pre-commit hooks..."
pip install pre-commit
pre-commit install

# Verify environment
echo "🔍 Running Flutter doctor..."
flutter doctor -v

echo "✅ Development environment setup complete!"
echo "💡 Run 'flutter run' to start the application"
```

### 2. Development Server Script
Create `scripts/dev-server.sh`:
```bash
#!/bin/bash
set -e

echo "🔧 Starting Development Services"

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services..."
sleep 10

# Start Serverpod backend
echo "🚀 Starting Serverpod backend..."
cd serverpod
dart run bin/main.dart --mode development &
BACKEND_PID=$!
cd ..

echo "✅ Development services started!"
echo "📊 Backend PID: $BACKEND_PID"
echo "🌐 API available at: http://localhost:8080"
echo "💡 Run 'flutter run' to start the Flutter app"

# Wait for user input to stop services
echo "Press Ctrl+C to stop all services"
trap "kill $BACKEND_PID; docker-compose -f docker-compose.dev.yml down" EXIT
wait
```

### 3. Testing Script
Create `scripts/test.sh`:
```bash
#!/bin/bash
set -e

echo "🧪 Running Development Tests"

# Flutter tests
echo "📱 Running Flutter tests..."
flutter test --coverage

# Format code
echo "📝 Formatting code..."
dart format .

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze --fatal-infos --fatal-warnings

echo "✅ All tests passed!"
echo "📊 Coverage report generated at: coverage/lcov.info"
```

## Troubleshooting Common Issues

### 1. Flutter Doctor Issues
```bash
# Missing Android licenses
flutter doctor --android-licenses

# Xcode not found
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Chrome not found
# Install Chrome or specify Chrome executable path
flutter config --enable-web
```

### 2. Dependency Conflicts
```bash
# Clean dependencies
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### 3. Build Issues
```bash
# Clean build cache
flutter clean
cd android && ./gradlew clean && cd ..
cd ios && xcodebuild clean && cd ..

# Reset Flutter
flutter channel stable
flutter upgrade
```

### 4. Hot Reload Not Working
```bash
# Check for stateful widgets that use hot reload unsupported features
# Common issues:
# - Global variables initialization
# - Static field modifications
# - const declarations changes
# - main() function modifications

# Use hot restart instead
flutter run --hot
```

### 5. IDE Integration Issues
```bash
# VS Code Dart extension not working
# Ensure Dart SDK path is correct
# Restart VS Code
# Check Dart: Show Skipped Paths setting

# IntelliJ Flutter plugin issues
# Invalidate caches and restart
# Check Flutter SDK path in IDE settings
```

## Performance Optimization

### 1. Flutter Performance
```bash
# Enable Skia for web
flutter run -d chrome --web-renderer skia

# Profile mode for performance testing
flutter run --profile

# Release build testing
flutter build apk --release
flutter build ios --release
```

### 2. Development Machine Optimization
```bash
# Increase Flutter cache size
export FLUTTER_ROOT_CACHE_SIZE=1024

# Use SSD for development
# Ensure sufficient RAM (16GB+)

# Close unnecessary applications during development
```

### 3. Network Optimization
```bash
# Use local development server
# Configure API endpoints in .env.local
# Use Flutter DevTools for performance profiling
flutter pub global activate devtools
flutter pub global run devtools
```

## Security Best Practices

### 1. Environment Variables
```bash
# Never commit .env files
# Add to .gitignore:
.env.local
.env.staging
.env.production

# Use dart-define for sensitive values
flutter run --dart-define=API_KEY=your_key
```

### 2. API Keys Management
```bash
# Use AWS Secrets Manager for production
# Use local .env for development
# Rotate keys regularly
```

### 3. Code Security
```bash
# Run security scans
flutter pub deps --style=compact
dart analyze --fatal-infos

# Check for vulnerabilities
# Use GitHub Dependabot
```

## Development Resources

### 1. Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Serverpod Documentation](https://serverpod.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Project Architecture](../architecture/tech-stack.md)

### 2. Tools
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
- [Flutter Inspector](https://docs.flutter.dev/tools/flutter-inspector)
- [Performance Profiler](https://docs.flutter.dev/tools/devtools/performance)

### 3. Community
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Discussions](https://github.com/flutter/flutter/discussions)

## Validation Checklist

Before starting development, verify:

- [ ] Flutter SDK installed and configured
- [ ] Development IDE set up with required extensions
- [ ] Git configuration completed
- [ ] Platform-specific tools installed (Android Studio/Xcode)
- [ ] Repository cloned and dependencies installed
- [ ] Environment variables configured
- [ ] Pre-commit hooks installed
- [ ] Docker services running (if applicable)
- [ ] Backend server accessible
- [ ] Flutter application runs without errors
- [ ] Hot reload/hot restart working
- [ ] Development tools configured

## Getting Help

If you encounter issues during setup:

1. Check this troubleshooting section
2. Search the project's GitHub Issues
3. Ask questions in the team's Slack/ Discord channel
4. Review Flutter and Serverpod documentation
5. Contact the development team lead

Remember: A properly configured development environment is essential for productive and efficient development. Don't hesitate to ask for help if you encounter any issues!