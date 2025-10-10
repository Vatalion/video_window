# Craft Video Marketplace

A comprehensive Flutter-based mobile marketplace platform for video content creators to monetize their work through auction-based sales and direct purchases.

## 🎯 Project Overview

Craft Video Marketplace is a cross-platform mobile application built with Flutter and Serverpod that enables video creators to:

- **Create & Manage Video Content** - Capture, edit, and publish professional video content
- **Auction-Based Monetization** - Sell videos through competitive bidding systems
- **Direct Sales & Commerce** - Enable instant purchases and digital delivery
- **Social Commerce Integration** - Build community around video content
- **Mobile-First Experience** - Native iOS and Android applications

## 🏗️ Architecture

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| **Frontend** | Flutter | 3.19.6 |
| **Language** | Dart | 3.5.6 |
| **Backend** | Serverpod | 2.9.x |
| **Database** | PostgreSQL | 15+ |
| **Cache** | Redis | 7+ |
| **Infrastructure** | AWS | Various services |

### Key Features

- **🎥 Video Creation Suite** - Professional video capture and editing tools
- **🏪 Content Marketplace** - Auction-based and direct sales models
- **📱 Native Mobile Apps** - iOS and Android with platform-specific optimizations
- **🔐 Secure Payments** - Stripe Connect with PCI SAQ A compliance
- **📊 Analytics Dashboard** - Real-time insights and business intelligence
- **🛡️ Enterprise Security** - Multi-layer security architecture

## 📁 Project Structure

```
video_window/
├── lib/                     # Flutter application code
├── android/                 # Android-specific code
├── ios/                     # iOS-specific code
├── docs/                    # Comprehensive documentation
│   ├── prd.md              # Product Requirements Document
│   ├── architecture/       # Technical architecture
│   ├── stories/           # User stories organized by epic
│   └── experiments/       # Technical spikes and research
└── tools/                  # Development and build tools
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.19.6+
- Dart 3.5.6+
- PostgreSQL 15+
- Redis 7+
- Xcode 15+ (for iOS)
- Android Studio (for Android)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd video_window
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Development Setup

For detailed development setup instructions, see:
- [Development Guide](docs/development.md)
- [Architecture Documentation](docs/architecture/)
- [Coding Standards](docs/architecture/coding-standards.md)

## 📚 Documentation

### Core Documents
- **[Product Requirements](docs/prd.md)** - Complete product specification
- **[Architecture Overview](docs/architecture/tech-stack.md)** - Technical architecture
- **[User Stories](docs/stories/)** - Feature breakdown by epic

### Key Epics
1. **[Identity & Access](docs/stories/01.identity-access/)** - Authentication & user management
2. **[Content Creation](docs/stories/03.content-creation-publishing/)** - Video creation tools
3. **[Marketplace](docs/stories/04.shopping-discovery/)** - Shopping & auction features
4. **[Commerce](docs/stories/05.checkout-fulfillment/)** - Payment & checkout
5. **[Mobile Experience](docs/stories/08.mobile-experience/)** - Native mobile features
6. **[Platform Infrastructure](docs/stories/09.platform-infrastructure/)** - Core services

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## 🏗️ Build & Deploy

### Development Build
```bash
flutter build apk --debug
flutter build ios --debug
```

### Production Build
```bash
flutter build apk --release
flutter build ios --release
```

For deployment instructions, see the [Architecture Documentation](docs/architecture/).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Licensing

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [docs/](docs/)
- **Architecture**: [docs/architecture/](docs/architecture/)
- **User Stories**: [docs/stories/](docs/stories/)
- **Issues**: [GitHub Issues](<repository-url>/issues)
- **Discussions**: [GitHub Discussions](<repository-url>/discussions)

---

## 📊 Project Status

**Current Version**: 0.1.0 (Development)
**Last Updated**: 2025-01-09
**Development Branch**: `001-build-a-platform`

### Development Progress

- ✅ Product Requirements Document
- ✅ Technical Architecture
- ✅ User Stories & Epics
- ✅ Development Environment Setup
- 🔄 Implementation in Progress

---

*Built with ❤️ using Flutter and Serverpod*