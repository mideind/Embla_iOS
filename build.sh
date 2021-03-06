# Build script for the Embla iOS app
# Only used for CI build tests.
#
# Builds an unsigned app binary in debug mode.
#
# xcodebuild output is fed through xcpretty to reduce build log
# verbosity and keep log length within a reasonable limit.

xcodebuild  -parallelizeTargets \
            -workspace "Embla.xcworkspace" \
            -scheme "Embla" \
            -configuration "Debug" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            clean build \
            | xcpretty -c && exit ${PIPESTATUS[0]}
