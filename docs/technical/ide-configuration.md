# IDE Configuration Guide

## Overview

This guide provides comprehensive IDE configuration procedures for optimal development experience across different editors and platforms. Proper IDE setup significantly improves productivity, code quality, and debugging capabilities.

## Supported IDEs

### Primary (Recommended)
- **VS Code** - Lightweight, extensible, excellent Flutter support
- **IntelliJ IDEA Ultimate** - Full-featured, strong Android integration

### Secondary
- **Android Studio** - Flutter/Android development focused
- **Vim/Neovim** - For terminal-based workflows

## VS Code Configuration

### 1. Installation and Setup

#### VS Code Installation
```bash
# macOS
brew install --cask visual-studio-code

# Windows (using Chocolatey)
choco install vscode

# Ubuntu
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code
```

#### Essential Extensions
Create `.vscode/extensions.json`:
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "dart-code.debugger-dart",
    "alexisvt.flutter-snippets",
    "nash.awesome-flutter-intellisense",
    "jeroen-meijer.pubspec-assist",
    "robert-brunhage.flutter-riverpod-snippets",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode-remote.remote-containers",
    "ms-vscode.vscode-docker",
    "hashicorp.terraform",
    "timonwong.shellcheck",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-eslint",
    "streetsidesoftware.code-spell-checker",
    "ms-vscode.vscode-git-graph",
    "eamodio.gitlens",
    "ms-vscode.test-adapter-converter",
    "dart-code.flutter-test-adapter"
  ]
}
```

#### Workspace Settings
Create `.vscode/settings.json`:
```json
{
  // Dart & Flutter Configuration
  "dart.flutterSdkPath": "/Users/username/development/flutter",
  "dart.lineLength": 100,
  "dart.insertArgumentPlaceholders": true,
  "dart.completeFunctionCalls": true,
  "dart.previewLsp": true,
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false,

  // Editor Configuration
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "editor.fontSize": 14,
  "editor.fontFamily": "JetBrains Mono, Consolas, monospace",
  "editor.fontLigatures": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,

  // File Associations
  "files.associations": {
    "*.arb": "json",
    "*.g.dart": "dart",
    "*.freezed.dart": "dart"
  },
  "emmet.includeLanguages": {
    "dart": "html"
  },

  // Search Configuration
  "search.exclude": {
    "**/build": true,
    "**/.dart_tool": true,
    "**/.flutter-plugins": true,
    "**/.flutter-plugins-dependencies": true
  },

  // Git Configuration
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "git.confirmSync": false,
  "gitlens.advanced.messages": {
    "suppressCommitHasNoPreviousCommitWarning": false,
    "suppressCommitNotFoundWarning": false,
    "suppressFileNotUnderSourceControlWarning": false,
    "suppressGitVersionWarning": false,
    "suppressLineUncommittedWarning": false,
    "suppressNoRepositoryWarning": false,
    "suppressResultsExplorerNotice": false,
    "suppressShowKeyBindingsNotice": true,
    "suppressUpdateNotice": false,
    "suppressWelcomeNotice": true
  },

  // Testing Configuration
  "testExplorer.hideWhen": {
    "defaultProfile": true
  },

  // Debug Configuration
  "debug.allowBreakpointsEverywhere": true,
  "debug.console.fontSize": 14,
  "debug.console.wordWrap": true,

  // Terminal Configuration
  "terminal.integrated.fontFamily": "JetBrains Mono",
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.shell.osx": "/bin/zsh",
  "terminal.integrated.shell.linux": "/bin/bash",
  "terminal.integrated.shell.windows": "C:\\Program Files\\Git\\bin\\bash.exe",

  // Flutter Specific
  "[dart]": {
    "editor.defaultFormatter": "dart-code.dart-code",
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false
  },

  // Miscellaneous
  "extensions.autoUpdate": true,
  "workbench.colorTheme": "Dark+ (default dark)",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.startupEditor": "welcome",
  "telemetry.enableTelemetry": false
}
```

### 2. Launch Configurations

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "craft_marketplace (debug)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=FLUTTER_ENV=development",
        "--dart-define=API_BASE_URL=http://localhost:8080"
      ],
      "env": {
        "FLUTTER_WEB_USE_SKIA": "true"
      }
    },
    {
      "name": "craft_marketplace (profile)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=FLUTTER_ENV=staging"
      ],
      "flutterMode": "profile"
    },
    {
      "name": "craft_marketplace (release)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=FLUTTER_ENV=production"
      ],
      "flutterMode": "release"
    },
    {
      "name": "craft_marketplace (test)",
      "type": "dart",
      "request": "launch",
      "program": "test/main_test.dart"
    }
  ]
}
```

### 3. Task Configuration

Create `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Flutter: Get Dependencies",
      "type": "shell",
      "command": "flutter",
      "args": ["pub", "get"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Flutter: Clean",
      "type": "shell",
      "command": "flutter",
      "args": ["clean"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Flutter: Analyze",
      "type": "shell",
      "command": "flutter",
      "args": ["analyze", "--fatal-infos", "--fatal-warnings"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Flutter: Test",
      "type": "shell",
      "command": "flutter",
      "args": ["test", "--coverage"],
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Flutter: Build APK",
      "type": "shell",
      "command": "flutter",
      "args": ["build", "apk", "--release"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Dart: Format",
      "type": "shell",
      "command": "dart",
      "args": ["format", "."],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    }
  ]
}
```

### 4. Debugging and Inspections

#### Flutter DevTools Integration
```json
{
  "dart.devToolsTheme": "dark",
  "dart.devToolsLogFile": "logs/devtools.log",
  "dart.flutterAdditionalArgs": [
    "--dart-define=FLUTTER_ENV=development"
  ]
}
```

#### Code Lenses
```json
{
  "dart.enableSdkFormatter": true,
  "dart.enableCompletionCommitCharacters": true,
  "dart.previewHotReloadOnSaveWatcher": true,
  "dart.flutterTrackWidgetCreation": true
}
```

## IntelliJ IDEA Configuration

### 1. Installation and Setup

#### Required Plugins
- **Flutter** - Core Flutter support
- **Dart** - Dart language support
- **.env files support** - Environment variable files
- **Terraform** - Infrastructure as code
- **Docker** - Container support
- **GitToolBox** - Enhanced Git integration
- **Rainbow Brackets** - Code readability
- **Key Promoter X** - Shortcut learning

#### IDE Settings

#### General Configuration
```
File → Settings → Editor → General
- Auto-import: Enable
- Remove unused imports: Enable
- Show import popup: Enable
- Optimize imports on the fly: Enable

File → Settings → Editor → Code Style → Dart
- Right margin: 100
- Tab size: 2
- Indent: 2
- Continuation indent: 4
```

#### Flutter Configuration
```
File → Settings → Languages & Frameworks → Flutter
- Flutter SDK path: /path/to/flutter
- Additional options: --dart-define=FLUTTER_ENV=development
- Hot reload on save: Enable

File → Settings → Languages & Frameworks → Dart
- Dart SDK path: Auto-detected
- SDK version: Latest stable
- Generate @immutable classes: Enable
- Enable Dart type inference for SDK: Enable
```

#### Version Control Configuration
```
File → Settings → Version Control → Git
- SSH executable: Built-in
- Enable VCS integration: Git
- Check in policy: Check code style and analysis

File → Settings → Version Control → Commit Dialog
- Perform code analysis: Enable
- Cleanup: Optimize imports, Reformat code
```

### 2. Live Templates

#### Flutter Widget Templates
```
Template: stful
Description: Flutter StatefulWidget
Abbreviation: stful
Template text:
class $CLASS_NAME$ extends StatefulWidget {
  const $CLASS_NAME$({Key? key}) : super(key: key);

  @override
  State<$CLASS_NAME$> createState() => _$CLASS_NAME$State();
}

class _$CLASS_NAME$State extends State<$CLASS_NAME$> {
  @override
  Widget build(BuildContext context) {
    return $WIDGET$;
  }
}
```

#### BLoC Template
```
Template: bloc
Description: BLoC pattern template
Abbreviation: bloc
Template text:
class $BLOC_NAME$Bloc extends Bloc<$BLOC_NAME$Event, $BLOC_NAME$State> {
  $BLOC_NAME$Bloc(this.$REPOSITORY$) : super($BLOC_NAME$Initial()) {
    on<$EVENT$>($EVENT_HANDLER$);
  }

  final $REPOSITORY_TYPE$ $REPOSITORY$;
}
```

### 3. Debugging Configuration

#### Run/Debug Configurations
```
Name: craft_marketplace_debug
Type: Flutter
File: lib/main.dart
Additional arguments: --dart-define=FLUTTER_ENV=development
VM options: --enable-vm-service
```

#### Breakpoint Configuration
```
- Exception breakpoints: Enable all
- Line breakpoints: Enable
- Conditional breakpoints: Enable for complex scenarios
- Watch expressions: For variable monitoring
```

## Android Studio Configuration

### 1. Flutter Plugin Setup
```
File → Settings → Plugins
- Install Flutter plugin (includes Dart)
- Restart IDE
```

### 2. Code Style Configuration
```
File → Settings → Editor → Code Style → Dart
- Set right margin to 100
- Configure imports and formatting
- Enable "Arrange code" on commit
```

### 3. Emulator Configuration
```
Tools → AVD Manager
- Create Pixel 7 Pro API 33 emulator
- Configure with sufficient storage
- Enable hardware acceleration
```

## Vim/Neovim Configuration

### 1. Plugin Setup

#### vim-plug Configuration
```vim
" ~/.vimrc or ~/.config/nvim/init.vim
call plug#begin('~/.vim/plugged')

" Dart/Flutter support
Plug 'dart-lang/dart-vim-plugin'
Plug 'thosakwe/vim-flutter'
Plug 'natebosch/vim-lsc'
Plug 'natebosch/vim-lsc-dart'

" General development
Plug 'preservim/nerdtree'
Plug 'itchyny/lightline.vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

call plug#end()
```

#### Configuration
```vim
" Dart configuration
let g:dart_format_on_save = 1
let g:dart_style_line_length = 100
let g:dart_trailing_comma_indent = 'inherit'
let g:dart_use_lsc = 1

" Flutter configuration
let g:flutter_command = 'flutter'
let g:flutter_hot_reload_on_save = 1
let g:flutter_hot_restart = 1

" General settings
set number
set relativenumber
set tabstop=2
set shiftwidth=2
set expandtab
set colorcolumn=100
```

### 2. LSP Configuration
```lua
" ~/.config/nvim/lua/lsp.lua
local lspconfig = require('lspconfig')

lspconfig.dartls.setup({
  settings = {
    dart = {
      analysisExcludedFolders = {".fvm/flutter_sdk"},
      lineLength = 100,
      completeFunctionCalls = true,
      showTodos = true,
    }
  }
})
```

## Common IDE Configuration Tasks

### 1. Code Formatting

#### VS Code
```json
{
  "[dart]": {
    "editor.defaultFormatter": "dart-code.dart-code"
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  }
}
```

#### IntelliJ
```
Settings → Editor → Code Style → Dart
- Set right margin to 100
- Configure tabulation and spacing
- Enable "Reformat code" on commit
```

### 2. Import Organization

#### VS Code
```json
{
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  }
}
```

#### IntelliJ
```
Settings → Editor → Code Style → Dart → Imports
- Enable "Optimize imports on the fly"
- Configure import order and layout
```

### 3. Code Analysis

#### Static Analysis Configuration
Create `analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
    avoid_print: error
    prefer_single_quotes: error
    sort_constructors_first: error
    sort_unnamed_constructors_first: error

linter:
  rules:
    - prefer_single_quotes
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - avoid_print
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - unnecessary_const
    - unnecessary_new
```

## Debugging Configuration

### 1. VS Code Debug Settings
```json
{
  "debug.allowBreakpointsEverywhere": true,
  "debug.inlineValues": "on",
  "debug.showBreakpointsOverview": true,
  "debug.toolBarLocation": "docked"
}
```

### 2. IntelliJ Debug Settings
```
Build, Execution, Deployment → Debugger
- Enable "Show values inline"
- Enable "Alternative view for collections"
- Configure stepping behavior
```

### 3. Breakpoint Management
```javascript
// VS Code launch configurations
{
  "type": "dart",
  "request": "attach",
  "name": "Attach to Flutter",
  "deviceId": "chrome"
}
```

## Productivity Features

### 1. Code Snippets

#### VS Code Snippets
Create `.vscode/craft-marketplace.code-snippets`:
```json
{
  "Flutter BLoC": {
    "prefix": "bloc",
    "body": [
      "class ${1:Feature}Bloc extends Bloc<${1:Feature}Event, ${1:Feature}State> {",
      "  ${1:Feature}Bloc(this.${2:repository}) : super(${1:Feature}Initial()) {",
      "    on<${3:Event}>(${4:handler});",
      "  }",
      "",
      "  final ${5:RepositoryType} ${2:repository};",
      "}"
    ],
    "description": "Create a BLoC class"
  },
  "Flutter Stateful Widget": {
    "prefix": "stful",
    "body": [
      "class ${1:WidgetName} extends StatefulWidget {",
      "  const ${1:WidgetName}({Key? key}) : super(key: key);",
      "",
      "  @override",
      "  State<${1:WidgetName}> createState() => _${1:WidgetName}State();",
      "}",
      "",
      "class _${1:WidgetName}State extends State<${1:WidgetName}> {",
      "  @override",
      "  Widget build(BuildContext context) {",
      "    return ${2:Container()};",
      "  }",
      "}"
    ],
    "description": "Create a StatefulWidget"
  }
}
```

### 2. Live Templates (IntelliJ)
- Configure frequently used patterns
- Widget templates, BLoC patterns, repository patterns
- Custom code generation templates

### 3. Multi-cursor and Selection
```bash
# VS Code multi-cursor shortcuts
Ctrl+D    # Select next occurrence
Ctrl+Alt+Up/Down  # Add cursor above/below
Ctrl+Shift+L     # Select all occurrences
```

## Troubleshooting IDE Issues

### 1. Flutter Doctor Issues
```bash
# Run Flutter doctor to identify issues
flutter doctor -v

# Common fixes:
# - Update Flutter SDK
# - Restart IDE
# - Check SDK paths
# - Reinstall extensions/plugins
```

### 2. Extension/Plugin Issues
```bash
# VS Code
# - Disable problematic extensions
# - Reset VS Code settings
# - Clear extension cache

# IntelliJ
# - Invalidate caches and restart
# - Reinstall plugins
# - Reset IDE settings
```

### 3. Performance Issues
```
# Increase memory allocation
# - Disable unused plugins
# - Configure file watchers
# - Optimize indexing settings
# - Use exclude patterns for large folders
```

## IDE Maintenance

### 1. Regular Tasks
- Update IDE and plugins monthly
- Clean caches and indexes quarterly
- Review and optimize settings
- Update Flutter SDK regularly

### 2. Backup Configuration
```
# VS Code
- Export settings using Settings Sync
- Backup extensions.json and settings.json
- Document custom configurations

# IntelliJ
- Export settings (File → Export Settings)
- Backup configuration directory
- Document custom live templates
```

### 3. Team Standardization
- Share IDE configuration files
- Document preferred extensions/plugins
- Standardize code formatting rules
- Create onboarding documentation

## Validation Checklist

Before starting development, verify:

- [ ] IDE installed and updated
- [ ] Required extensions/plugins installed
- [ ] Flutter SDK path configured
- [ ] Code style settings applied
- [ ] Debug configuration working
- [ ] Hot reload/restart functional
- [ ] Git integration configured
- [ ] Code analysis rules enabled
- [ ] Live templates/snippets configured
- [ ] Performance optimizations applied
- [ ] Team standards documented

A well-configured IDE is crucial for productive development. Take the time to set up your environment properly and customize it to your workflow preferences.