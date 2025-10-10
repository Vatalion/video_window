# Development Setup Guide

**Effective Date:** 2025-10-09
**Review Date:** 2025-12-09
**Owner:** Development Team

## Prerequisites

Before starting development setup, ensure you have:

### System Requirements
- **Operating System:** macOS 12+, Windows 10+, or Ubuntu 20.04+
- **Memory:** 16GB+ RAM recommended
- **Storage:** 10GB+ free disk space
- **Network:** Stable internet connection for package downloads

### Required Accounts
- **GitHub:** Access to repository (contact team lead for invitation)
- **Git:** Configured with SSH keys or personal access token
- **AWS:** Account for backend deployment (provided by team)
- **Stripe:** Test account credentials (provided by team)

## Quick Start (15 minutes)

### 1. Install Flutter SDK

```bash
# Download Flutter 3.19.6
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.19.6-stable.tar.xz

# Extract to home directory
tar xf flutter_macos_3.19.6-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter --version
# Expected: Flutter 3.19.6 • channel stable
```

### 2. Configure Development Environment

```bash
# Clone repository
git clone https://github.com/[org]/video_window.git
cd video_window

# Install dependencies
flutter pub get

# Verify environment
flutter doctor -v
```

### 3. Run the Application

```bash
# Start development server
flutter run -d chrome

# Or for mobile devices
flutter devices  # List available devices
flutter run -d <device-id>
```

## Detailed Setup Guide

### Step 1: Environment Setup

#### Flutter SDK Installation

**macOS:**
```bash
# Using Homebrew (recommended)
brew install --cask flutter

# Or manual download
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.19.6-stable.tar.xz
sudo tar xf flutter_macos_3.19.6-stable.tar.xz -C /Applications
export PATH="/Applications/flutter/bin:$PATH"
echo 'export PATH="/Applications/flutter/bin:$PATH"' >> ~/.zshrc
```

**Windows:**
```powershell
# Download from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\flutter
# Add to PATH: C:\flutter\bin
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "User")
```

**Linux:**
```bash
# Download and extract
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz
tar xf flutter_linux_3.19.6-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.bashrc
```

#### Verify Installation

```bash
flutter doctor -v
```

Expected output should show:
```
[✓] Flutter (Channel stable, 3.19.6, on macOS ...)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS devices
[✓] Chrome - develop for the web
[✓] Android Studio (version ...)
[✓] VS Code (version ...)
[✓] Connected device
```

### Step 2: IDE Configuration

#### VS Code Setup (Recommended)

1. **Install VS Code**
   ```bash
   # macOS
   brew install --cask visual-studio-code

   # Download from https://code.visualstudio.com/
   ```

2. **Install Required Extensions**
   ```bash
   # Install Flutter extension
   code --install-extension Dart-Code.flutter

   # Install additional useful extensions
   code --install-extension Dart-Code.dart-code
   code --install-extension ms-vscode.vscode-json
   code --install-extension bradlc.vscode-tailwindcss
   ```

3. **Configure VS Code Settings**
   ```json
   {
     "dart.flutterSdkPath": "/Applications/flutter/bin/flutter",
     "dart.debugExternalLibraries": false,
     "dart.debugSdkLibraries": false,
     "files.autoSave": "afterDelay",
     "editor.formatOnSave": true,
     "editor.codeActionsOnSave": {
       "source.fixAll": true
     }
   }
   ```

#### Android Studio Setup

1. **Install Android Studio**
   - Download from https://developer.android.com/studio
   - Follow installation instructions for your OS

2. **Install Flutter Plugin**
   - Open Android Studio
   - Go to File → Settings → Plugins
   - Search for "Flutter" and install
   - Restart Android Studio

3. **Configure Android SDK**
   ```bash
   # Set ANDROID_HOME environment variable
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

### Step 3: Project Setup

#### Clone and Configure Repository

```bash
# Clone the repository
git clone https://github.com/[org]/video_window.git
cd video_window

# Verify Flutter version
flutter --version
# Should show: Flutter 3.19.6

# Install dependencies
flutter pub get

# Run initial setup script (if exists)
dart scripts/setup.dart
```

#### Environment Configuration

Create environment file:

```bash
# Create .env file
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Development Environment
FLUTTER_ENV=development
API_BASE_URL=https://dev-api.craftmarketplace.com

# Authentication (get from team)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# AWS (for backend development)
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1

# Firebase (for push notifications)
FIREBASE_PROJECT_ID=craftmarketplace-dev
```

### Step 4: Backend Setup (Serverpod)

#### Install Serverpod CLI

```bash
# Activate Serverpod CLI
dart pub global activate serverpod_cli

# Verify installation
serverpod --version
# Should show version 2.9.x
```

#### Set Up Database

```bash
# Navigate to server directory
cd server

# Install dependencies
dart pub get

# Set up PostgreSQL database
createdb craftmarketplace_dev

# Run database migrations
serverpod run migrate

# Start Serverpod server
serverpod run
```

### Step 5: Testing Setup

#### Run Unit Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### Run Integration Tests

```bash
# Start integration test server
flutter drive --target=test_driver/app_test.dart

# Or run specific integration tests
flutter test integration_test/
```

## Development Workflow

### Daily Development Routine

1. **Sync with Main Branch**
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Start Development Server**
   ```bash
   flutter run -d chrome --hot
   ```

4. **Make Changes and Test**
   ```bash
   # Run tests frequently
   flutter test

   # Check code formatting
   dart format .

   # Run static analysis
   flutter analyze
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: implement user authentication flow"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create Pull Request on GitHub
   ```

### Code Quality Standards

#### Code Formatting

```bash
# Format all Dart files
dart format .

# Format specific file
dart format lib/main.dart

# Set up automatic formatting
dart fix --apply
```

#### Static Analysis

```bash
# Run analysis with strict settings
flutter analyze --fatal-infos --fatal-warnings

# Check for specific issues
flutter analyze | grep "error\|warning"
```

#### Testing Requirements

```bash
# Minimum test coverage before commit
flutter test --coverage && \
  genhtml coverage/lcov.info -o coverage/html && \
  # Require 80% coverage
  if [ $(lcov --summary coverage/lcov.info | grep -E 'lines......:' | grep -o '[0-9]+\.[0-9]+' | cut -d'.' -f1) -lt 80 ]; then \
    echo "Coverage below 80%"; exit 1; \
  fi
```

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues

**Issue:** Android licenses not accepted
```bash
flutter doctor --android-licenses
# Accept all licenses with 'y'
```

**Issue:** Xcode not found (macOS)
```bash
# Install Xcode from App Store
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**Issue:** Chrome not found
```bash
# Install Chrome or specify browser path
flutter run -d chrome --web-browser-path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

#### Build Issues

**Issue:** Dependency conflicts
```bash
# Clean and rebuild
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

**Issue:** Gradle build failed (Android)
```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

**Issue:** iOS build failed
```bash
# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

### Performance Issues

#### Slow Hot Reload

```bash
# Increase build performance
export FLUTTER_FRAMEWORK_DIR=/Applications/flutter/bin/cache/artifacts/engine/ios-release
flutter run --profile
```

#### Memory Issues

```bash
# Increase Flutter memory limit
export FLUTTER_TEST_MEMORY=4096
flutter test
```

## Development Tools

### Recommended VS Code Extensions

```bash
# Essential extensions
code --install-extension Dart-Code.flutter
code --install-extension ms-vscode.vscode-json
code --install-extension bradlc.vscode-tailwindcss

# Additional useful extensions
code --install-extension ms-vscode.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-vscode-remote.remote-containers
```

### Debugging Tools

```bash
# Flutter Inspector
flutter run --debug

# Observatory debugger
flutter run --debug --observatory-port=8080

# Profile mode for performance testing
flutter run --profile
```

### Package Management

```bash
# Add new dependency
flutter pub add package_name

# Add dev dependency
flutter pub add --dev package_name

# Remove dependency
flutter pub remove package_name

# Upgrade dependencies
flutter pub upgrade

# Outdated packages
flutter pub outdated
```

## Contributing Guidelines

### Branch Naming Convention

```
feature/user-authentication
bugfix/login-validation
hotfix/security-patch
release/v1.2.0
docs/api-documentation
refactor/user-service
```

### Commit Message Format

```
type(scope): description

feat(auth): add biometric authentication
fix(ui): resolve layout overflow on small screens
docs(readme): update setup instructions
refactor(api): simplify payment processing logic
test(integration): add e2e checkout flow tests
```

### Pull Request Requirements

1. **Code Quality**
   - All tests passing
   - 80%+ test coverage
   - No analysis warnings/errors
   - Proper code formatting

2. **Documentation**
   - Update relevant README files
   - Add inline code comments
   - Update API documentation

3. **Testing**
   - Unit tests for new functions
   - Integration tests for new features
   - Manual testing checklist

## Resources

### Official Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Serverpod Documentation](https://serverpod.dev/docs)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)

### Community Resources
- [Flutter YouTube Channel](https://www.youtube.com/c/FlutterDev)
- [Flutter Community Discord](https://discord.gg/flutter)
- [Stack Overflow flutter tag](https://stackoverflow.com/questions/tagged/flutter)

### Project-Specific Resources
- [Architecture Guide](architecture.md)
- [Coding Standards](architecture/coding-standards.md)
- [Version Policy](version-policy.md)
- [API Documentation](architecture/openapi-spec.yaml)

---

## Support

For development setup issues:

1. **Check this guide first** for common problems
2. **Search existing issues** in GitHub repository
3. **Create new issue** with:
   - Operating system and version
   - Flutter version (`flutter --version`)
   - Error messages (full output)
   - Steps to reproduce

4. **Contact team** via:
   - Slack: #development-help
   - Email: dev-team@craftmarketplace.com

---

**Last Updated:** 2025-10-09
**Next Review:** 2025-12-09
**Maintainers:** Development Team