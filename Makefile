# Makefile for Greynir iOS app

XCODE_WORKSPACE := "GreynirApp.xcworkspace"
XCODE_SCHEME := "Greynir"
BUILD_DIR := "products"

all: clean build_unsigned

build_unsigned:
	mkdir -p $(BUILD_DIR)

	xcodebuild  -parallelizeTargets \
	            -workspace $(XCODE_WORKSPACE) \
	            -scheme $(XCODE_SCHEME) \
	            -configuration "Debug" \
	            CODE_SIGN_IDENTITY="" \
	            CODE_SIGNING_ALLOWED=NO \
	            CODE_SIGNING_REQUIRED=NO \
	            clean build > /dev/null

clean:
	xcodebuild -workspace $(XCODE_WORKSPACE) -scheme $(XCODE_SCHEME) clean
