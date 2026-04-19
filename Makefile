APP_NAME      := Pluck
SCHEME        := Pluck
CONFIG        := release
BUILD_DIR     := build
APP_BUNDLE    := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS      := $(APP_BUNDLE)/Contents
MACOS_DIR     := $(CONTENTS)/MacOS
RESOURCES     := $(CONTENTS)/Resources
INFO_PLIST_SRC := Sources/Pluck/Resources/Info.plist
ENTITLEMENTS  := Sources/Pluck/Resources/entitlements.plist
BINARY_SRC    := .build/$(CONFIG)/$(APP_NAME)

CODESIGN_IDENTITY ?= -
# For a notarized release: set to your Developer ID Application identity.

INSTALL_DIR   := /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app

.PHONY: all build bundle sign run test clean install uninstall reset-permissions

all: bundle

build:
	swift build -c $(CONFIG)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES)
	cp $(BINARY_SRC) $(MACOS_DIR)/$(APP_NAME)
	cp $(INFO_PLIST_SRC) $(CONTENTS)/Info.plist
	@$(MAKE) sign

sign:
	codesign --force --options=runtime \
		--entitlements $(ENTITLEMENTS) \
		--sign "$(CODESIGN_IDENTITY)" \
		$(APP_BUNDLE)

run: bundle
	open $(APP_BUNDLE)

test:
	swift test

clean:
	swift package clean
	rm -rf $(BUILD_DIR)

# Drop the running dev copy, replace /Applications/Pluck.app with the
# fresh build, and launch the installed copy.
install: bundle
	@pkill -TERM $(APP_NAME) 2>/dev/null || true
	@sleep 1
	ditto $(APP_BUNDLE) $(INSTALLED_APP)
	open $(INSTALLED_APP)

uninstall:
	@pkill -TERM $(APP_NAME) 2>/dev/null || true
	rm -rf $(INSTALLED_APP)

# Clears Accessibility + Input Monitoring grants for this bundle. Launch
# the app after this to re-run onboarding.
reset-permissions:
	tccutil reset All md.getdesign.pluck
