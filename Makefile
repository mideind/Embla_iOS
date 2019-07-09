# Makefile for Greynir iOS app

XCODE_WORKSPACE := "GreynirApp.xcworkspace"
XCODE_SCHEME := "Greynir"
BUILD_DIR := "products"

all: clean build_unsigned

release: clean build_signed

build_unsigned:
	mkdir -p $(BUILD_DIR)

	xcodebuild  -parallelizeTargets \
	            -workspace $(XCODE_WORKSPACE) \
	            -scheme $(XCODE_SCHEME) \
	            -configuration "Debug" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            CODE_SIGN_IDENTITY="" \
	            CODE_SIGNING_ALLOWED=NO \
                CODE_SIGNING_REQUIRED=NO \
	            clean build

build_signed:
	mkdir -p $(BUILD_DIR)
	xcodebuild  -parallelizeTargets \
	            -project "$(XCODE_WORKSPACE)" \
	            -scheme "$(XCODE_SCHEME)" \
	            -configuration "Debug" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            clean build

clean:
	xcodebuild -workspace $(XCODE_WORKSPACE) -scheme $(XCODE_SCHEME) clean
	rm -rf products/* 2> /dev/null
