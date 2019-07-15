# Build script for Greynir iOS app
# Only used for Travis CI testing.
#
# Builds an unsigned app binary in debug mode.
#
# xcodebuild output is fed through xcpretty to reduce build log
# verbosity and keep it within Travis log length limit.

xcodebuild  -parallelizeTargets \
            -jobs 4 \
            -workspace "GreynirApp.xcworkspace" \
            -scheme "Greynir" \
            -configuration "Debug" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            clean build \
            | xcpretty -c && exit ${PIPESTATUS[0]}
