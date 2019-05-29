# Greynir App

iOS app to access the Greynir query engine via voice.

Requires iOS 9.2+.

## Build instructions

Building the app requires Xcode 10+ and the latest version of [CocoaPods](https://cocoapods.org).

From repository root, run the following command:

```
$ pod install
```

Once installation is done, open `GreynirApp.xcworkspace` with Xcode and build. 

NB: In order to function correctly, the app requires valid API keys for Google's Speech API and AWS Polly's Icelandic speech synthesis API.

## GPL License

This program and its source code is released under the 
[GNU General Public License v3.](https://www.gnu.org/licenses/gpl-3.0.html)
