.PHONY: all install deps release debug

all: release
install: install-release

RIME_BIN_DIR = librime/dist/bin
RIME_LIB_DIR = librime/dist/lib
DERIVED_DATA_PATH = build

RIME_LIBRARY_FILE_NAME = librime.1.dylib
RIME_LIBRARY = lib/$(RIME_LIBRARY_FILE_NAME)

PACKAGE = package/Squirrel.pkg
DEPS_CHECK = $(RIME_LIBRARY)

INSTALL_NAME_TOOL = $(shell xcrun -find install_name_tool)
INSTALL_NAME_TOOL_ARGS = -add_rpath @loader_path/../Frameworks

.PHONY: librime copy-rime-binaries

$(RIME_LIBRARY):
	$(MAKE) librime

librime:
	@echo "Using prebuilt librime"
	$(MAKE) copy-rime-binaries

copy-rime-binaries:
	mkdir -p lib bin
	cp -L $(RIME_LIB_DIR)/$(RIME_LIBRARY_FILE_NAME) lib/
	cp $(RIME_BIN_DIR)/rime_deployer bin/
	cp $(RIME_BIN_DIR)/rime_dict_manager bin/
	$(INSTALL_NAME_TOOL) $(INSTALL_NAME_TOOL_ARGS) bin/rime_deployer
	$(INSTALL_NAME_TOOL) $(INSTALL_NAME_TOOL_ARGS) bin/rime_dict_manager

deps: librime

# Only support Apple Silicon (arm64)
ARCHS = arm64
BUILD_SETTINGS += ARCHS="$(ARCHS)"
BUILD_SETTINGS += ONLY_ACTIVE_ARCH=YES
export CMAKE_OSX_ARCHITECTURES = $(ARCHS)

ifdef MACOSX_DEPLOYMENT_TARGET
BUILD_SETTINGS += MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)"
endif

BUILD_SETTINGS += COMPILER_INDEX_STORE_ENABLE=YES

release: $(DEPS_CHECK)
	mkdir -p $(DERIVED_DATA_PATH)
	xcodebuild -project Squirrel.xcodeproj -configuration Release -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH) $(BUILD_SETTINGS) build

debug: $(DEPS_CHECK)
	mkdir -p $(DERIVED_DATA_PATH)
	xcodebuild -project Squirrel.xcodeproj -configuration Debug -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH)  $(BUILD_SETTINGS) build

.PHONY: package archive

$(PACKAGE):
ifdef DEV_ID
	bash package/sign_app "$(DEV_ID)" "$(DERIVED_DATA_PATH)"
endif
	bash package/make_package "$(DERIVED_DATA_PATH)"
ifdef DEV_ID
	productsign --sign "Developer ID Installer: $(DEV_ID)" package/Squirrel.pkg package/Squirrel-signed.pkg
	rm package/Squirrel.pkg
	mv package/Squirrel-signed.pkg package/Squirrel.pkg
	xcrun notarytool submit package/Squirrel.pkg --keychain-profile "$(DEV_ID)" --wait
	xcrun stapler staple package/Squirrel.pkg
endif

package: release $(PACKAGE)

archive: package
	bash package/make_archive

DSTROOT = /Library/Input Methods
SQUIRREL_APP_ROOT = $(DSTROOT)/Squirrel.app

.PHONY: permission-check install-debug install-release

permission-check:
	[ -w "$(DSTROOT)" ] && [ -w "$(SQUIRREL_APP_ROOT)" ] || sudo chown -R ${USER} "$(DSTROOT)"

install-debug: debug permission-check
	rm -rf "$(SQUIRREL_APP_ROOT)"
	cp -R $(DERIVED_DATA_PATH)/Build/Products/Debug/Squirrel.app "$(DSTROOT)"
	DSTROOT="$(DSTROOT)" RIME_NO_PREBUILD=1 bash scripts/postinstall

install-release: release permission-check
	rm -rf "$(SQUIRREL_APP_ROOT)"
	cp -R $(DERIVED_DATA_PATH)/Build/Products/Release/Squirrel.app "$(DSTROOT)"
	DSTROOT="$(DSTROOT)" bash scripts/postinstall

.PHONY: clean clean-deps

clean:
	rm -rf build > /dev/null 2>&1 || true
	rm build.log > /dev/null 2>&1 || true
	rm bin/* > /dev/null 2>&1 || true
	rm lib/* > /dev/null 2>&1 || true

clean-package:
	rm -rf package/*.pkg > /dev/null 2>&1 || true

clean-deps:
	rm -rf download > /dev/null 2>&1 || true
