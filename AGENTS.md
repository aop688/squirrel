# AGENTS.md - Squirrel

This file contains essential information for AI coding agents working on the Squirrel project.

## Project Overview

**Squirrel (鼠鬚管)** is a macOS input method editor (IME) powered by the [Rime Input Method Engine](https://rime.im). It provides an intelligent, customizable Chinese input experience for macOS users.

- **Bundle ID**: `im.rime.inputmethod.Squirrel` (same as upstream on purpose: this build replaces the
  official Squirrel and cannot be installed alongside it)
- **Input mode**: a single mode, `im.rime.inputmethod.Squirrel.Hans`
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
- `UserNotifications`: deploy start / success / failure notifications
- `Carbon`: Key code mappings (virtual key codes)
- `QuartzCore`: Core Animation (CALayer, CAShapeLayer)

### Dependencies (vendored in repo, no git submodules)
- `librime/dist/`: prebuilt librime 1.16.0 (`a251145`) dylib, tools and headers (no plugins).
  `librime/include` is a symlink to `dist/include`, which also carries `rime/key_table.h` and `X11/keysym*.h`
  (not in the upstream release archive, required by the bridging header).
- `data/prelude/`: `default.yaml`, `key_bindings.yaml`, `punctuation.yaml` from
  [rime-prelude](https://github.com/rime/rime-prelude) (`082425e`); `default.yaml`'s `schema_list` is cut to `rime_ice`.
- `data/rime_ice/`: the only bundled input schema (雾凇拼音, simplified Chinese), a lite cut of
  [rime-ice](https://github.com/iDvel/rime-ice). `cn_dicts/{8105,base,others}` are synced from upstream (`da1fbe6`);
  `ext`/`tencent` are not bundled. The schema is trimmed locally, so do not overwrite it with upstream's.
  `base.dict.yaml` is then pruned by `scripts/trim_dicts.py` (drops weight <= 10 and phrases over 8 characters:
  ~120k of 543k removed, ~423k kept); re-run it after every upstream sync.

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
├── data/
│   ├── rime_ice/               # rime_ice schema + dicts (source, tracked)
│   └── prelude/                # default.yaml, key_bindings.yaml, punctuation.yaml (tracked)
├── librime/dist/               # Vendored prebuilt librime (tracked)
├── bin/, lib/                  # Copied from librime/dist by `make copy-rime-binaries` (gitignored)
├── package/                    # Packaging scripts (make_package, make_archive, sign_app)
├── scripts/postinstall         # pkg postinstall: register, prebuild, enable input source
├── scripts/trim_dicts.py       # prune rime_ice base dict after an upstream sync
└── Squirrel.xcodeproj/         # Xcode project
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
   - No `squirrel.yaml` is bundled: without a user `~/Library/Rime/squirrel.yaml`,
     the hardcoded dark defaults in `SquirrelTheme` are used

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
- **Xcode** (full Xcode, not just Command Line Tools; `xcodebuild` is required)
- librime is prebuilt and vendored; CMake/Boost are not needed

### Key Make Targets

```bash
# Prepare deps: copy librime into bin/ lib/ (no network needed)
./action-install.sh

# Build (arm64 only, see ARCHS in Makefile)
make release
make debug

# Create installer package / versioned archive
make package
make archive

# Install locally for testing
make install

# Clean build artifacts / librime download cache
make clean
make clean-deps
```

### Environment Variables

```bash
# Optional: Code signing and notarization
export DEV_ID="Your Apple ID name"

# Optional: Deployment target
export MACOSX_DEPLOYMENT_TARGET='13.0'

# Optional: refresh librime/dist from the upstream release pinned in action-install.sh
update_librime=1 ./action-install.sh
```

### Bundled Data

- The Xcode "Copy Shared Support Files" phase copies the files in `data/prelude/` and `data/rime_ice/`
  directly into `Contents/SharedSupport/`; there is no generation step.
- `cn_dicts` is a folder reference, so it keeps its subdirectory (`rime_ice.dict.yaml` imports `cn_dicts/*`).
- The file list is static in `project.pbxproj`; to bundle a new file, add it to the project's
  "Copy Shared Support Files" phase.

### CI Build (GitHub Actions)

- `commit-ci.yml`: every push (and manual run). Builds and uploads the `.pkg` and a zipped `Squirrel.app` as artifacts.
- `pull-request-ci.yml`: same build for PRs.
- `release-ci.yml`: on tags (and manual run). Tags create a draft GitHub release with `Squirrel-<version>.pkg`.
- SwiftLint and Periphery run with `continue-on-error`; check their logs, a green run does not mean they passed.
- Builds are unsigned unless `DEV_ID` is configured.

```bash
./action-build.sh package   # what CI runs
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
1. **SwiftLint**: Code style validation (non-blocking)
2. **Build**: Compilation for arm64
3. **Periphery**: Dead code detection (non-blocking)

### Testing Commands

```bash
# Install locally and test
make install

# Or for debug build
make install-debug

# Force reload after changes
Squirrel.app/Contents/MacOS/Squirrel --reload
```

### Resource Usage Baseline

Measured 2026-10-09 on the installed build (1.1.2, arm64) after 10 days of uptime. Use it as a reference
when checking for regressions.

| Metric | Value | Notes |
|---|---|---|
| Physical footprint | 18 MB (peak 18.6 MB) | What Activity Monitor shows; ~12 MB of it is malloc (librime sessions/caches) |
| RSS | 60 MB | Includes shared system libraries and clean mmap pages |
| Dictionary mmap | ~13.6 MB resident | `rime_ice.table.bin` (17 MB) is mapped read-only and reclaimable, not counted in footprint |
| CPU | 0.0% idle, 50 s total over 10 days | 4 threads, energy impact 0.0 |
| App bundle on disk | 48 MB | Mostly librime dylib and prebuilt dictionaries |
| User DB | 68 KB | `~/Library/Rime/rime_ice.userdb`, grows with use |

No memory growth was seen over the uptime (peak is within 0.5 MB of current).

```bash
footprint $(pgrep -x Squirrel)             # physical footprint by category
vmmap --summary $(pgrep -x Squirrel)       # incl. mapped dictionary files
ps -o rss,%cpu,etime,time -p $(pgrep -x Squirrel)
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
- **Log directory**: `$TMPDIR/rime.squirrel/` (per-user temp dir: `$(getconf DARWIN_USER_TEMP_DIR)rime.squirrel`)

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

1. Update `CURRENT_PROJECT_VERSION` in the Xcode project
2. Push a tag; `release-ci.yml` builds `Squirrel-<version>.pkg` and opens a draft release
3. For a signed local build: `make package DEV_ID="..."` (signs, notarizes and staples)

There is no auto-update mechanism.

## Common Development Tasks

### Adding a New UI String

1. Add to `resources/Localizable.xcstrings`
2. Use `NSLocalizedString("key", comment: "context")` in code

### Modifying the Candidate Window

- Layout logic: `SquirrelPanel.swift`
- Rendering: `SquirrelView.swift`
- Theme properties: `SquirrelTheme.swift`

### Rime Plugins

No plugins are bundled (the lite rime_ice schema needs none). Adding one means copying it from the
librime release into `librime/dist/lib/rime-plugins/`, adding a "Copy Rime plugins" phase
(destination: Frameworks/rime-plugins) in `project.pbxproj`, and dropping the `rm` in `action-install.sh`.

### Debugging Tips

1. **Enable debug logging**: Check `$(getconf DARWIN_USER_TEMP_DIR)rime.squirrel/` for logs
2. **Console.app**: Filter by "Squirrel" process
3. **Reset configuration**: Delete `~/Library/Rime/` and redeploy
4. Deploy start / success / failure are shown as system notifications (if the user allowed them);
   on failure, check the log directory
5. Before logout Rime is finalized; if the logout is cancelled, the next key event restarts it
   (`SquirrelApplicationDelegate.ensureRimeRunning()`)

## Troubleshooting

### Build Issues

```bash
# Clean everything and rebuild
make clean clean-deps
rm -rf build
./action-install.sh
make release
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
