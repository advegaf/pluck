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
ICON_PNG_SRC  := Sources/Pluck/Resources/AppIcon.png
ICON_ICNS_OUT := $(RESOURCES)/AppIcon.icns
BINARY_SRC    := .build/$(CONFIG)/$(APP_NAME)

CODESIGN_IDENTITY ?= -
# For a notarized release: set to your Developer ID Application identity.
# `--timestamp` requires Apple's timestamp server, which adhoc (`-`) can't use.
TIMESTAMP_FLAG := $(if $(filter -,$(CODESIGN_IDENTITY)),,--timestamp)

INSTALL_DIR   := /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app

# --- Release (DMG) plumbing -------------------------------------------------
VERSION               := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $(INFO_PLIST_SRC))
SIGN_IDENTITY_RELEASE := Developer ID Application: Angel Vega Figueroa (DV483F72N3)
NOTARY_PROFILE        := selfcontrol-notary
DMG_OUT               := $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg

.PHONY: all build bundle sign run test clean install uninstall reset-permissions full-reset dmg release

all: bundle

build:
	swift build -c $(CONFIG)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES)
	cp $(BINARY_SRC) $(MACOS_DIR)/$(APP_NAME)
	cp $(INFO_PLIST_SRC) $(CONTENTS)/Info.plist
	Scripts/gen-icns.sh $(ICON_ICNS_OUT)
	@$(MAKE) sign

sign:
	codesign --force --options=runtime $(TIMESTAMP_FLAG) \
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

# Nuke everything: running process, /Applications copy, TCC grants,
# UserDefaults domain, build artifacts. Then rebuild + reinstall from
# scratch. Use when the app needs to look like a fresh first launch.
full-reset:
	@pkill -TERM $(APP_NAME) 2>/dev/null || true
	@sleep 1
	$(MAKE) uninstall
	$(MAKE) reset-permissions
	-defaults delete md.getdesign.pluck 2>/dev/null || true
	$(MAKE) clean
	$(MAKE) install

# Signed + notarized + stapled DMG for distribution. Driven by
# Scripts/release.sh (modeled on advegaf/selfcontrol-mastered's pipeline).
# Reuses the Developer ID cert + notary profile already in the keychain.
dmg: clean
	CODESIGN_IDENTITY="$(SIGN_IDENTITY_RELEASE)" \
	NOTARY_PROFILE="$(NOTARY_PROFILE)" \
	VERSION="$(VERSION)" \
	APP_NAME="$(APP_NAME)" \
	Scripts/release.sh

release: dmg
