<img src="Embla/Assets.xcassets/EmblaLogo.imageset/embla_logo%401x.png" align="right" width="192" height="192">

# Embla iOS client

Embla is an iOS app to access the Icelandic-language [Greynir](https://greynir.is) query engine via voice.

Written in Objective-C for iOS 12.0+. Probably only builds on a recent version of macOS.

## Build instructions

Building the app requires [Xcode](https://developer.apple.com/xcode/) 11+ and [CocoaPods](https://cocoapods.org).

After cloning the repository, run the following command from the repo root:

```
$ pod install
```

Once installation is complete, open `Embla.xcworkspace` with Xcode and build. Alternatively, you can build an unsigned debug app binary by running the build script from the repository root:

```
$ ./build.sh
```

NB: In order to function correctly, the app requires a valid API key for Google's Speech-to-Text API. The key should be saved in the following text file:

* `Keys/GoogleAPI.key`

## Credits

The Embla iOS client uses Carnegie Mellon University's [Pocketsphinx](https://github.com/cmusphinx/pocketsphinx) library, the [CMU CMUCMLTK](http://cmusphinx.sourceforge.net) library, Politepix’s [OpenEars](http://www.politepix.com/openears) and Google's Speech-to-Text API for speech recognition.

## GPL License

This program and its source code is &copy; 2019-2020 [Miðeind ehf.](https://miðeind.is) and is released as open source software under the terms and conditions of the [GNU General Public License v3.](https://www.gnu.org/licenses/gpl-3.0.html)
