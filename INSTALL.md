# How to Rime with Squirrel

> Instructions to build this Squirrel fork - the Rime frontend for macOS

## Build in the cloud

Every push to GitHub runs `commit-ci.yml`, which builds `Squirrel.pkg` and a zipped
`Squirrel.app` and uploads them as workflow artifacts (kept for 90 days). You can also
start it manually from the Actions page ("commit ci" → "Run workflow").

Pushing a tag runs `release-ci.yml`, which creates a draft GitHub release with
`Squirrel-<version>.pkg`.

## Manually build and install Squirrel

### Prerequisites

Install **Xcode** from the App Store and select it (Command Line Tools alone are not enough,
`xcodebuild` is required):

``` sh
sudo xcode-select -s /Applications/Xcode.app
```

Only Apple Silicon (arm64) builds are supported. CMake and Boost are **not** needed:
librime is vendored as prebuilt binaries in `librime/dist`.

### Checkout the code

``` sh
git clone https://github.com/aop688/squirrel.git

cd squirrel
```

There are no git submodules; librime and all bundled data are part of the repository.

### Prepare dependencies

``` sh
./action-install.sh
```

This copies librime into `lib/` and `bin/`. No network access is needed: the bundled data
(`data/prelude/` and `data/rime_ice/`) is tracked and copied into the app by Xcode.

To upgrade librime, edit `rime_version` and `rime_git_hash` in `action-install.sh`, then run:

``` sh
update_librime=1 ./action-install.sh
```

and commit the updated `librime/dist`.

### Build Squirrel

``` sh
make            # same as: make release
make debug      # debug build
```

Optional environment variables:

``` sh
export DEV_ID="Your Apple ID name" # include this to codesign and notarize, optional
export MACOSX_DEPLOYMENT_TARGET='13.0' # optional, lower version than 13.0 is not tested
```

## Install it on your Mac

This build replaces the official Squirrel: it uses the same bundle ID and install location,
so the two cannot be installed side by side.

### Make Package

``` sh
make package
```

Define `DEV_ID` to automatically handle code signing and [notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution) (Apple Developer ID needed)

To make this work, you need a `Developer ID Installer: (your name/org)` and set your name/org as `DEV_ID` env variable.

To make notarization work, you also need to save your credential under the same name as above.

```
xcrun notarytool store-credentials 'your name/org'
```

You **don't** need to define `DEV_ID` if you don't intend to distribute the package.

An unsigned package downloaded from the internet is blocked by Gatekeeper; remove the
quarantine flag before opening it:

``` sh
xattr -dr com.apple.quarantine Squirrel.pkg
```

### Directly Install

**You might need to precede with sudo, and without a logout, the App might not work properly. Direct install is not very recommended.**

Once built, you can install and try it live on your Mac computer:

``` sh
make install
```

## Clean Up Artifacts

After installation or after a failed attempt, you may want to start over. Before you do so, **make sure you have cleaned up artifacts from previous build.**

To clean **Squirrel** artifacts, without touching dependencies, run:

``` sh
make clean
```

To clean up **dependencies** (the librime download cache; the vendored `librime/dist` is kept), run:

``` sh
make clean-deps
```

To clean up **packages**, run:

``` sh
make clean-package
```

If you want to clean all above, do all.

That's it, a verbal journal. Thanks for riming with Squirrel.
