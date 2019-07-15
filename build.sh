# Build script for Greynir iOS app
# Used for Travis CI tests

xcodebuild  -parallelizeTargets \
            -jobs 4 \
            -workspace "GreynirApp.xcworkspace" \
            -scheme "Greynir" \
            -configuration "Debug" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            clean build \
            | xcpretty -c && test ${PIPESTATUS[0]} -eq 0
