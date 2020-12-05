<img src="Embla/Assets.xcassets/EmblaLogo.imageset/embla_logo%401x.png" align="right" width="224" height="224" style="margin-left:20px;">

# Embla iOS client


Embla is a voice-driven virtual assistant app that uses the Icelandic-language 
[Greynir](https://greynir.is) query engine. This is the repository for the Embla iOS client.

Written in Objective-C for iOS 12.0+. Probably only builds on a recent version of macOS.

## Build instructions

Building the app requires [Xcode](https://developer.apple.com/xcode/) 11+ and [CocoaPods](https://cocoapods.org).

After cloning the repository, run the following command from the repo root:

```
$ pod install
```

Once installation is complete, open `Embla.xcworkspace` with Xcode and build. Alternatively, you can build an 
unsigned debug app binary by running the build script from the repository root:

```
$ ./build.sh
```

The build script requires [`xcpretty`](https://github.com/xcpretty/xcpretty), which you can install with the following 
command:

```
sudo gem install xcpretty
```

NB: In order to function correctly, the app requires a valid API key for Google's Speech-to-Text API. The key should
be  saved in the following text file:

* `Keys/GoogleAPI.key`

## Screenshots

<p float="left">
  <img src="Screenshots/embla_screenshot_55_1.png" width="30%" />
  <img src="Screenshots/embla_screenshot_55_2.png" width="30%" /> 
  <img src="Screenshots/embla_screenshot_55_3.png" width="30%" />
</p>

## Credits

The Embla iOS client uses Carnegie Mellon University's [Pocketsphinx](https://github.com/cmusphinx/pocketsphinx)
and Politepix’s [OpenEars](http://www.politepix.com/openears) for hotword detection,  and Google's
[Speech-to-Text API](https://cloud.google.com/speech-to-text) for speech recognition. Speech synthesis is
accomplished via voices commissioned by [Blindrafélagið](https://blind.is), the Icelandic Association of the Visually Impaired.

## GPL License

This program and its source code is &copy; 2019-2020 [Miðeind ehf.](https://miðeind.is) and is released as open source 
software under the terms and conditions of the [GNU General Public License v3.](https://www.gnu.org/licenses/gpl-3.0.html) 
Alternative licensing arrangements are negotiable.
