# AGENTS.md - Squirrel

This file contains essential information for AI coding agents working on the Squirrel project.

## Project Overview

**Squirrel (鼠鬚管)** is a macOS input method editor (IME) powered by the [Rime Input Method Engine](https://rime.im). It provides an intelligent, customizable Chinese input experience for macOS users.

- **Bundle ID**: `im.rime.inputmethod.Squirrel`
- **Minimum macOS Version**: macOS 13.0+
- **License**: GPL v3
- **Primary Language**: Swift (with C/Objective-C bridging)

## Technology Stack

### Primary Languages & Frameworks
- **Swift 5.x**: Main application code (10 source files)
- **C/C++**: Via librime (Rime engine library)
- **Objective-C**: Bridging headers for C library integration

### Key Frameworks
- `InputMethodKit`: macOS input method infrastructure
- `AppKit`: UI components (NSPanel, NSTextView)
- `Sparkle`: Automatic software updates
- `UserNotifications`: System notifications
- `Carbon`: Key code mappings (virtual key codes)
- `QuartzCore`: Core Animation (CALayer, CAShapeLayer)

### Dependencies (Git Submodules)
- `librime/`: Rime input method engine (C++ library)
- `plum/`: Rime configuration manager (東風破)
- `Sparkle/`: Auto-update framework

## Project Structure

```
├── sources/                    # Main Swift source code
│   ├── Main.swift              # Application entry point
│   ├── SquirrelInputController.swift  # Core IME controller
│   ├── SquirrelApplicationDelegate.swift  # App lifecycle & Rime setup
│   ├── SquirrelPanel.swift     # Candidate window (NSPanel)
│   ├── SquirrelView.swift      # Custom view rendering
│   ├── SquirrelTheme.swift     # UI theme & styling
│   ├── SquirrelConfig.swift    # Configuration management
│   ├── InputSource.swift       # Input method registration
│   ├── MacOSKeyCodes.swift     # Key code mapping (macOS → Rime)
│   ├── BridgingFunctions.swift # Swift/C interop utilities
│   └── Squirrel-Bridging-Header.h  # Objective-C bridging header
├── resources/                  # Localization & plist files
│   ├── Info.plist              # App bundle configuration
│   ├── InfoPlist.xcstrings     # Info.plist localization
│   └── Localizable.xcstrings   # UI string localization
├── data/                       # Runtime data files
│   ├── squirrel.yaml           # Default configuration
│   └── plum/                   # Schema data (generated)
├── bin/                        # Binary tools
│   ├── rime_deployer           # Rime deployment tool
│   ├── rime_dict_manager       # Dictionary management
│   └── rime-install            # Package installer script
├── lib/                        # Shared libraries
│   ├── librime.1.dylib         # Rime engine library
│   └── rime-plugins/           # Rime plugin dylibs
├── package/                    # Packaging scripts
├── scripts/                    # Installation scripts
├── Squirrel.xcodeproj/         # Xcode project
└── Frameworks/                 # 3rd-party frameworks (Sparkle)
```

## Architecture

### Core Components

1. **SquirrelInputController** (`SquirrelInputController.swift`)
   - Extends `IMKInputController` (InputMethodKit)
   - Handles keyboard input events
   - Manages Rime sessions per application
   - Processes key events and converts to Rime keycodes
   - Handles candidate selection and paging

2. **SquirrelPanel** (`SquirrelPanel.swift`)
   - Custom `NSPanel` for candidate display
   - Supports horizontal/vertical layouts
   - Handles mouse interactions (click, scroll)
   - Auto-positioning based on cursor location

3. **SquirrelView** (`SquirrelView.swift`)
   - Custom `NSView` with Core Animation layers
   - Renders themed candidate backgrounds
   - Smooth rounded corners and shadows
   - Text layout with `NSTextLayoutManager`

4. **SquirrelTheme** (`SquirrelTheme.swift`)
   - UI styling and color schemes
   - Font management (candidate, label, comment)
   - Dark mode support
   - Configurable via `squirrel.yaml`

5. **SquirrelConfig** (`SquirrelConfig.swift`)
   - Wrapper around Rime configuration API
   - Caching for performance
   - Color parsing (hex format)

### Input Method Flow

```
User Input → NSEvent
    ↓
SquirrelInputController.handle(_:client:)
    ↓
MacOSKeyCodes (keycode translation)
    ↓
librime API (rimeAPI.process_key)
    ↓
Rime Engine Processing
    ↓
Update UI (SquirrelPanel/SquirrelView)
    ↓
Commit Text → Client Application
```

## Build System

### Prerequisites
- **Xcode 14.0+** (for Universal binary support)
- **CMake** (for building librime)
- **Boost C++ Libraries** (via Homebrew/MacPorts or source)

### Key Make Targets

```bash
# Build release version
make release

# Build debug version
make debug

# Build dependencies (librime, data files)
make deps

# Create installer package
make package

# Install locally for testing
make install

# Clean build artifacts
make clean
make clean-deps
```

### Environment Variables

```bash
# Required for building librime
export BOOST_ROOT="/path/to/boost"

# Optional: Code signing
export DEV_ID="Your Apple ID name"

# Optional: Build Universal binary
export BUILD_UNIVERSAL=1
export ARCHS='arm64 x86_64'

# Optional: Deployment target
export MACOSX_DEPLOYMENT_TARGET='13.0'

# Optional: Include plum recipes
export PLUM_TAG=":preset"  # or ":extra"
```

### CI Build (GitHub Actions)

The project uses GitHub Actions for continuous integration:

```bash
# Download prebuilt librime binaries
./action-install.sh

# Build and package
./action-build.sh package
```

## Code Style Guidelines

### SwiftLint Configuration (`.swiftlint.yml`)

```yaml
# Disabled rules
- force_cast
- force_try
- todo

# Line length
line_length: 200

# Function/Type limits
function_body_length: 200
type_body_length:
  - 300 (warning)
  - 400 (error)
file_length:
  warning: 800
  error: 1200

# Naming
identifier_name:
  min_length:
    warning: 3
    error: 2
  excluded: [i, URL, of, by]
```

### Coding Conventions

1. **File Headers**: Standard Xcode header comments with creation date
2. **Access Control**: Use `final` for classes not intended for subclassing
3. **Naming**: Swift-style camelCase for variables/functions, PascalCase for types
4. **Comments**: Minimal inline comments; complex logic should be self-documenting
5. **Localization**: Use `NSLocalizedString` with comment context

### Custom Operators

The project defines a custom nil-coalescing assignment operator:

```swift
// Assign only if right side is non-nil
linear ?= config.getString("style/candidate_list_layout").map { $0 == "linear" }
```

## Testing Strategy

### Manual Testing
- No automated unit tests in the current codebase
- Testing is done via manual installation (`make install`)
- Test in various applications (Terminal, Safari, TextEdit, etc.)

### CI Checks
1. **SwiftLint**: Code style validation
2. **Build**: Compilation for target architectures
3. **Periphery**: Dead code detection

### Testing Commands

```bash
# Install locally and test
make install

# Or for debug build
make install-debug

# Force reload after changes
Squirrel.app/Contents/MacOS/Squirrel --reload
```

## Localization

- **Format**: Xcode String Catalogs (`.xcstrings`)
- **Files**:
  - `resources/Localizable.xcstrings` - UI strings
  - `resources/InfoPlist.xcstrings` - Bundle info strings
- **Languages**: English, Chinese (Traditional/Simplified)

## Configuration

### User Configuration
- **User directory**: `~/Library/Rime/`
- **Main config**: `squirrel.yaml`
- **Log directory**: `/tmp/rime.squirrel/`

### Key Configuration Options

```yaml
# style/candidate_list_layout: linear | stacked
# style/text_orientation: horizontal | vertical
# style/inline_preedit: bool
# style/color_scheme: string (preset name)
# style/font_face: string
# style/font_point: number
```

## Security Considerations

1. **Code Signing**: Required for distribution; optional for local builds
2. **Notarization**: Automated in `make package` when `DEV_ID` is set
3. **Sandboxing**: Input method components have limited sandboxing
4. **Input Method Kit**: Runs with user's privileges

## Deployment

### Release Process

1. Update version in Xcode project
2. Build with `make package DEV_ID="..."`
3. Notarization happens automatically via `xcrun notarytool`
4. Staple ticket: `xcrun stapler staple package/Squirrel.pkg`
5. Create archive with Sparkle appcast: `make archive`

### Auto-Update (Sparkle)

- **Feed URL**: `https://rime.github.io/release/squirrel/appcast.xml`
- **Public Key**: Embedded in Info.plist (`SUPublicEDKey`)
- **Enabled by default**: Users can disable in preferences

## Common Development Tasks

### Adding a New UI String

1. Add to `resources/Localizable.xcstrings`
2. Use `NSLocalizedString("key", comment: "context")` in code

### Modifying the Candidate Window

- Layout logic: `SquirrelPanel.swift`
- Rendering: `SquirrelView.swift`
- Theme properties: `SquirrelTheme.swift`

### Adding Rime Plugins

```bash
# In librime/ directory
bash install-plugins.sh user/repo
# Example: bash install-plugins.sh rime/librime-lua
```

### Debugging Tips

1. **Enable debug logging**: Check `/tmp/rime.squirrel/` for logs
2. **Console.app**: Filter by "Squirrel" process
3. **Reset configuration**: Delete `~/Library/Rime/` and redeploy
4. **Safe mode**: Detects crash loops and prevents re-launch

## Troubleshooting

### Build Issues

```bash
# Clean everything and rebuild
make clean clean-deps
rm -rf build Frameworks librime/dist

# Re-initialize submodules
git submodule update --init --recursive

# Download fresh dependencies
./action-install.sh
```

### Runtime Issues

- **IME not appearing**: Register with `Squirrel.app/Contents/MacOS/Squirrel --install`
- **Config not loading**: Run `Squirrel.app/Contents/MacOS/Squirrel --reload`
- **Crash on launch**: Check for problematic config in `~/Library/Rime/`

## Related Projects

- [librime](https://github.com/rime/librime): Rime input method engine
- [plum](https://github.com/rime/plum): Rime configuration manager
- [weasel](https://github.com/rime/weasel): Windows frontend
- [ibus-rime](https://github.com/rime/ibus-rime): Linux frontend

## Resources

- **Documentation**: https://rime.im/docs/
- **Wiki**: https://github.com/rime/home/wiki
- **Issues**: https://github.com/rime/squirrel/issues
- **Discussions**: https://github.com/rime/home/discussions
