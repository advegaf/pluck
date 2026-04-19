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

.PHONY: all build bundle sign run test clean

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
