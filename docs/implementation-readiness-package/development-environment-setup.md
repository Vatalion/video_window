# Development Environment Setup

**Automated Setup for Immediate Development Start**
**Version:** 1.0
**Date:** 2025-10-09
**Target Platforms:** macOS, Windows 10/11, Ubuntu 20.04+

## Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/video-window.git
cd video-window

# Run the automated setup
./scripts/setup.sh

# Verify installation
./scripts/verify.sh
```

## Prerequisites Checklist

### System Requirements
- [ ] **Operating System:** macOS 12+, Windows 10/11, or Ubuntu 20.04+
- [ ] **RAM:** Minimum 8GB, recommended 16GB
- [ ] **Storage:** Minimum 20GB free space
- [ ] **Internet:** Stable connection for downloads and dependencies

### Required Accounts
- [ ] **GitHub:** Access to repository with SSH keys configured
- [ ] **AWS:** Account access for infrastructure (if needed)
- [ ] **Slack:** Team workspace access
- [ ] **Google/Apple:** Developer accounts (for mobile testing)

### Optional Tools
- [ ] **Docker:** For containerized services
- [ ] **Postman:** For API testing
- [ ] **Device:** Physical iOS/Android device for testing

## Automated Setup Script

### Main Setup Script (`scripts/setup.sh`)

```bash
#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Install homebrew on macOS
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH
        if [[ $(detect_os) == "macos" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed"
    else
        print_status "Homebrew already installed"
    fi
}

# Install Git
install_git() {
    if ! command -v git &> /dev/null; then
        print_status "Installing Git..."
        if [[ $(detect_os) == "macos" ]]; then
            brew install git
        elif [[ $(detect_os) == "linux" ]]; then
            sudo apt-get update && sudo apt-get install -y git
        elif [[ $(detect_os) == "windows" ]]; then
            print_warning "Please install Git from https://git-scm.com/"
            return 1
        fi
        print_success "Git installed"
    else
        print_status "Git already installed"
    fi
}

# Install Flutter SDK
install_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_status "Installing Flutter SDK..."

        if [[ $(detect_os) == "macos" ]]; then
            brew install --cask flutter
        elif [[ $(detect_os) == "linux" ]]; then
            # Download Flutter
            wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz
            tar xf flutter_linux_3.19.6-stable.tar.xz
            sudo mv flutter /opt/
            echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
            export PATH="$PATH:/opt/flutter/bin"
        elif [[ $(detect_os) == "windows" ]]; then
            print_warning "Please install Flutter from https://flutter.dev/docs/get-started/install/windows"
            return 1
        fi

        print_success "Flutter SDK installed"
    else
        print_status "Flutter SDK already installed"
    fi

    # Run Flutter doctor
    print_status "Running Flutter doctor..."
    flutter doctor
}

# Install Dart
install_dart() {
    # Dart comes with Flutter, but we'll ensure it's properly configured
    if ! command -v dart &> /dev/null; then
        print_status "Dart not found. This should come with Flutter..."
        return 1
    else
        print_status "Dart already installed"
    fi
}

# Install Serverpod
install_serverpod() {
    if ! command -v serverpod &> /dev/null; then
        print_status "Installing Serverpod..."
        dart pub global activate serverpod_cli
        print_success "Serverpod installed"
    else
        print_status "Serverpod already installed"
    fi
}

# Install Node.js (for tools and scripts)
install_nodejs() {
    if ! command -v node &> /dev/null; then
        print_status "Installing Node.js..."
        if [[ $(detect_os) == "macos" ]]; then
            brew install node
        elif [[ $(detect_os) == "linux" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        print_success "Node.js installed"
    else
        print_status "Node.js already installed"
    fi
}

# Install VS Code and extensions
install_vscode() {
    if command -v code &> /dev/null; then
        print_status "Installing VS Code extensions..."

        # Flutter extension
        code --install-extension Dart-Code.flutter
        # Dart extension
        code --install-extension Dart-Code.dart-code
        # GitLens
        code --install-extensioneamhub.gitlens
        # Prettier
        code --install-extension Esbenp.prettier-vscode

        print_success "VS Code extensions installed"
    else
        print_warning "VS Code not found. Please install from https://code.visualstudio.com/"
    fi
}

# Set up Android development environment
setup_android() {
    print_status "Setting up Android development environment..."

    if [[ $(detect_os) == "macos" ]]; then
        # Install Java
        brew install openjdk@11

        # Set JAVA_HOME
        echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@11' >> ~/.zshrc
        echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc

        # Install Android Studio
        brew install --cask android-studio

    elif [[ $(detect_os) == "linux" ]]; then
        # Install Java
        sudo apt-get update
        sudo apt-get install -y openjdk-11-jdk

        # Download Android Studio
        wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz
        tar -xzf android-studio-2023.1.1.28-linux.tar.gz
        sudo mv android-studio /opt/

    elif [[ $(detect_os) == "windows" ]]; then
        print_warning "Please install Android Studio from https://developer.android.com/studio"
        return 1
    fi

    print_success "Android development environment setup complete"
}

# Set up iOS development environment (macOS only)
setup_ios() {
    if [[ $(detect_os) != "macos" ]]; then
        print_warning "iOS development is only supported on macOS"
        return 0
    fi

    print_status "Setting up iOS development environment..."

    # Install Xcode command line tools
    if ! xcode-select -p &> /dev/null; then
        xcode-select --install
        print_success "Xcode command line tools installed"
    else
        print_status "Xcode command line tools already installed"
    fi

    # Install CocoaPods
    if ! command -v pod &> /dev/null; then
        sudo gem install cocoapods
        print_success "CocoaPods installed"
    else
        print_status "CocoaPods already installed"
    fi

    print_warning "Please install Xcode from the App Store and run it once to accept the license"
}

# Install PostgreSQL
install_postgresql() {
    if ! command -v psql &> /dev/null; then
        print_status "Installing PostgreSQL..."
        if [[ $(detect_os) == "macos" ]]; then
            brew install postgresql@15
            brew services start postgresql@15
        elif [[ $(detect_os) == "linux" ]]; then
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        fi
        print_success "PostgreSQL installed"
    else
        print_status "PostgreSQL already installed"
    fi
}

# Install Redis
install_redis() {
    if ! command -v redis-server &> /dev/null; then
        print_status "Installing Redis..."
        if [[ $(detect_os) == "macos" ]]; then
            brew install redis
            brew services start redis
        elif [[ $(detect_os) == "linux" ]]; then
            sudo apt-get install -y redis-server
            sudo systemctl start redis
            sudo systemctl enable redis
        fi
        print_success "Redis installed"
    else
        print_status "Redis already installed"
    fi
}

# Configure Git settings
configure_git() {
    print_status "Configuring Git settings..."

    # Set default branch name
    git config --global init.defaultBranch develop

    # Set pull strategy
    git config --global pull.rebase true

    # Set core attributes
    git config --global core.autocrlf input

    print_success "Git configuration complete"
}

# Clone and setup project
setup_project() {
    print_status "Setting up project structure..."

    # Create project directory if it doesn't exist
    mkdir -p ~/development
    cd ~/development

    # Clone repository (adjust URL as needed)
    if [[ ! -d "video-window" ]]; then
        git clone https://github.com/your-org/video-window.git
    fi

    cd video-window

    # Install Flutter dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get

    # Install Serverpod dependencies
    print_status "Installing Serverpod dependencies..."
    cd serverpod
    dart pub get
    cd ..

    # Setup pre-commit hooks
    print_status "Setting up pre-commit hooks..."
    chmod +x scripts/pre-commit.sh
    cp scripts/pre-commit.sh .git/hooks/

    print_success "Project setup complete"
}

# Main setup function
main() {
    print_status "Starting development environment setup..."
    print_status "Detected OS: $(detect_os)"

    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        print_error "Please don't run this script as root"
        exit 1
    fi

    # Install dependencies based on OS
    case $(detect_os) in
        "macos")
            install_homebrew
            install_git
            install_flutter
            install_dart
            install_serverpod
            install_nodejs
            install_vscode
            setup_android
            setup_ios
            install_postgresql
            install_redis
            ;;
        "linux")
            install_git
            install_flutter
            install_dart
            install_serverpod
            install_nodejs
            setup_android
            install_postgresql
            install_redis
            ;;
        "windows")
            print_error "Windows setup requires manual steps. Please follow the Windows setup guide."
            exit 1
            ;;
        *)
            print_error "Unsupported operating system: $(detect_os)"
            exit 1
            ;;
    esac

    # Configure tools
    configure_git
    setup_project

    print_success "Development environment setup complete!"
    print_status "Please run './scripts/verify.sh' to verify your installation"

    # Next steps
    echo ""
    print_status "Next steps:"
    echo "1. Open a new terminal window to load all environment variables"
    echo "2. Run './scripts/verify.sh' to verify your installation"
    echo "3. Open Android Studio and install required SDK components"
    echo "4. Open Xcode (macOS) and accept the license"
    echo "5. Start developing!"
}

# Run main function
main "$@"
```

### Verification Script (`scripts/verify.sh`)

```bash
#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verification results
PASSED=0
FAILED=0

# Function to verify installation
verify_command() {
    local command=$1
    local name=$2

    if command -v $command &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name is installed"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is not installed"
        ((FAILED++))
        return 1
    fi
}

# Function to verify Flutter setup
verify_flutter() {
    echo -e "\n${BLUE}Verifying Flutter setup...${NC}"

    if command -v flutter &> /dev/null; then
        local flutter_version=$(flutter --version | head -n 1)
        echo -e "${GREEN}✓${NC} Flutter is installed: $flutter_version"

        # Check Flutter doctor
        echo -e "\n${BLUE}Running Flutter doctor:${NC}"
        flutter doctor

        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} Flutter is not installed"
        ((FAILED++))
        return 1
    fi
}

# Function to verify database connections
verify_databases() {
    echo -e "\n${BLUE}Verifying database connections...${NC}"

    # Check PostgreSQL
    if command -v psql &> /dev/null; then
        if pg_isready -q; then
            echo -e "${GREEN}✓${NC} PostgreSQL is running"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} PostgreSQL is not running"
            ((FAILED++))
        fi
    else
        echo -e "${RED}✗${NC} PostgreSQL is not installed"
        ((FAILED++))
    fi

    # Check Redis
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo -e "${GREEN}✓${NC} Redis is running"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} Redis is not running"
            ((FAILED++))
        fi
    else
        echo -e "${RED}✗${NC} Redis is not installed"
        ((FAILED++))
    fi
}

# Function to verify project setup
verify_project() {
    echo -e "\n${BLUE}Verifying project setup...${NC}"

    if [[ -d "serverpod" ]]; then
        echo -e "${GREEN}✓${NC} Serverpod directory exists"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Serverpod directory not found"
        ((FAILED++))
    fi

    if [[ -f "pubspec.yaml" ]]; then
        echo -e "${GREEN}✓${NC} Flutter pubspec.yaml exists"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Flutter pubspec.yaml not found"
        ((FAILED++))
    fi

    # Check if dependencies are installed
    if flutter pub deps &> /dev/null; then
        echo -e "${GREEN}✓${NC} Flutter dependencies are installed"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Flutter dependencies are not installed"
        ((FAILED++))
    fi
}

# Function to verify development tools
verify_dev_tools() {
    echo -e "\n${BLUE}Verifying development tools...${NC}"

    # Check VS Code
    if command -v code &> /dev/null; then
        echo -e "${GREEN}✓${NC} VS Code is installed"

        # Check Flutter extension
        if code --list-extensions | grep -q "Dart-Code.flutter"; then
            echo -e "${GREEN}✓${NC} Flutter extension is installed"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} Flutter extension is not installed"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} VS Code is not installed (optional)"
    fi

    # Check Git configuration
    if git config --global user.name &> /dev/null; then
        echo -e "${GREEN}✓${NC} Git is configured"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Git is not configured"
        ((FAILED++))
    fi
}

# Main verification function
main() {
    echo -e "${BLUE}Development Environment Verification${NC}"
    echo -e "${BLUE}===================================${NC}"

    # Verify basic tools
    verify_command "git" "Git"
    verify_command "dart" "Dart"
    verify_command "node" "Node.js"

    # Verify Flutter setup
    verify_flutter

    # Verify development tools
    verify_dev_tools

    # Verify databases
    verify_databases

    # Verify project setup
    verify_project

    # Summary
    echo -e "\n${BLUE}Verification Summary:${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"

    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All checks passed! Your development environment is ready.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some checks failed. Please review and fix the issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
```

## Platform-Specific Setup Guides

### macOS Setup

#### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later (from App Store)
- At least 20GB free disk space

#### Manual Steps
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install --cask android-studio
brew install --cask visual-studio-code

# Install Xcode from App Store
# Run Xcode once to accept license agreement

# Setup Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Install iOS dependencies (after Xcode setup)
sudo gem install cocoapods
```

### Windows Setup

#### Prerequisites
- Windows 10/11
- PowerShell 5.1 or later
- Visual Studio 2022 (with C++ desktop development)

#### Manual Setup Steps
```powershell
# Enable Windows Subsystem for Linux (optional but recommended)
wsl --install

# Download and install Flutter SDK
# Visit https://flutter.dev/docs/get-started/install/windows

# Download and install Android Studio
# Visit https://developer.android.com/studio

# Install Git for Windows
# Visit https://git-scm.com/download/win

# Install Visual Studio Code
# Visit https://code.visualstudio.com/

# Setup environment variables
# Add Flutter SDK to PATH
# Add Android SDK to PATH
```

### Linux Setup (Ubuntu/Debian)

#### Prerequisites
- Ubuntu 20.04+ or Debian 11+
- At least 10GB free disk space

#### Manual Steps
```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y curl git wget unzip zip apt-transport-https

# Install Java
sudo apt install -y openjdk-11-jdk

# Install Android Studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz
tar -xzf android-studio-2023.1.1.28-linux.tar.gz
sudo mv android-studio /opt/

# Setup Android environment variables
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
```

## IDE Configuration

### VS Code Setup

#### Recommended Extensions
```json
{
  "recommendations": [
    "Dart-Code.flutter",
    "Dart-Code.dart-code",
    "eamodio.gitlens",
    "esbenp.prettier-vscode",
    "ms-vscode.hexeditor",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense"
  ]
}
```

#### Workspace Settings (`.vscode/settings.json`)
```json
{
  "dart.flutterSdkPath": "flutter",
  "dart.lineLength": 80,
  "editor.rulers": [80],
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false,
  "search.exclude": {
    "**/.git": true,
    "**/.dart_tool": true,
    "**/build": true,
    "**/ios/Pods": true
  }
}
```

### Android Studio Setup

#### Required Plugins
- Flutter plugin
- Dart plugin
- Git Integration

#### Configuration Steps
1. Open Android Studio
2. Go to `Preferences/Settings` → `Plugins`
3. Install Flutter and Dart plugins
4. Restart Android Studio
5. Configure Flutter SDK path
6. Set up Android SDK and emulator

### Xcode Setup (macOS)

#### Configuration Steps
1. Install Xcode from App Store
2. Run Xcode and accept license agreement
3. Install command line tools: `xcode-select --install`
4. Install CocoaPods: `sudo gem install cocoapods`
5. Open iOS project in Xcode to verify setup

## Database Setup

### PostgreSQL Configuration

```bash
# Start PostgreSQL service
brew services start postgresql@15  # macOS
sudo systemctl start postgresql   # Linux

# Create development database
createdb video_window_dev

# Create test database
createdb video_window_test

# Connect to database
psql video_window_dev
```

#### Basic PostgreSQL Setup
```sql
-- Create development user
CREATE USER video_window_dev WITH PASSWORD 'dev_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE video_window_dev TO video_window_dev;

-- Create schema
CREATE SCHEMA IF NOT EXISTS app;
GRANT ALL ON SCHEMA app TO video_window_dev;
```

### Redis Configuration

```bash
# Start Redis service
brew services start redis  # macOS
sudo systemctl start redis  # Linux

# Test Redis connection
redis-cli ping
```

## Git Configuration

### SSH Key Setup
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy  # macOS
# or
xclip -sel clip < ~/.ssh/id_ed25519.pub  # Linux
```

### Git Configuration
```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"

# Set default branch
git config --global init.defaultBranch develop

# Set editor
git config --global core.editor "code --wait"

# Set pull strategy
git config --global pull.rebase true
```

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
# Run Flutter doctor with verbose output
flutter doctor -v

# Clear Flutter cache
flutter clean

# Get Flutter dependencies
flutter pub get

# Upgrade Flutter
flutter upgrade
```

#### Android Setup Issues
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools
```

#### iOS Setup Issues (macOS)
```bash
# Update CocoaPods
sudo gem install cocoapods
pod repo update

# Clear iOS build cache
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
pg_isready

# Check Redis status
redis-cli ping

# Restart services
brew services restart postgresql@15
brew services restart redis
```

### Performance Optimization

#### Flutter Performance
```bash
# Enable Web DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Profile app performance
flutter run --profile
```

#### Development Environment
```bash
# Increase file watchers (Linux)
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Optimize Git performance
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256
```

## Environment Variables

### Create `.env` file
```bash
# Create environment file
touch .env

# Add environment variables
echo "FLUTTER_ENV=development" >> .env
echo "API_URL=http://localhost:8080" >> .env
echo "DATABASE_URL=postgresql://video_window_dev:dev_password@localhost:5432/video_window_dev" >> .env
echo "REDIS_URL=redis://localhost:6379" >> .env
```

### Shell Configuration (`.zshrc` or `.bashrc`)
```bash
# Flutter
export PATH="$PATH:/opt/flutter/bin"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

# Java
export JAVA_HOME=/opt/homebrew/opt/openjdk@11
export PATH="$JAVA_HOME/bin:$PATH"

# Project-specific
export VIDEO_WINDOW_ENV=development
```

## Next Steps After Setup

1. **Verify Installation**: Run `./scripts/verify.sh` to confirm everything is working
2. **Create First Branch**: Create a feature branch for your first task
3. **Run Tests**: Ensure all tests pass with `flutter test`
4. **Start Development**: Begin implementing your first feature
5. **Join Team Communication**: Introduce yourself in team Slack channels

## Support

If you encounter any issues during setup:

1. **Check the logs**: Review any error messages carefully
2. **Consult the troubleshooting section**: Try the common fixes
3. **Ask the team**: Post in the development Slack channel
4. **Create an issue**: Document the problem with steps to reproduce

---

This setup guide ensures all team members have consistent, working development environments. The automated scripts handle most of the heavy lifting, while the manual steps provide flexibility for different platforms and preferences.