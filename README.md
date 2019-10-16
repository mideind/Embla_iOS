# Embla iOS client

Embla is an iOS app to access the [Greynir](https://greynir.is) query engine via voice.

Requires iOS 11.0+. Probably only builds on a relatively recent version of macOS.

## Build instructions

Building the app requires Xcode 10+ and a recent version of [CocoaPods](https://cocoapods.org).

From repository root, run the following command:

```
$ pod install
```

Once installation is done, open `Embla.xcworkspace` with Xcode and build. Alternatively, you can build an unsigned app binary by running the following command from the repository root:

```
./build.sh
```

NB: In order to function correctly, the app requires a valid API key for Google's Speech API. The key should be saved in the following text file:

* `Keys/GoogleAPI.key`

## Credits

The Embla iOS client uses Carnegie Mellon University's [Pocketsphinx](https://github.com/cmusphinx/pocketsphinx) library, the [CMU CMUCMLTK](http://cmusphinx.sourceforge.net) library  and Politepix’s [OpenEars](http://www.politepix.com/openears).

## GPL License

This program and its source code is &copy; 2019 Miðeind ehf. and is released as open source software under the terms and conditions of the [GNU General Public License v3.](https://www.gnu.org/licenses/gpl-3.0.html)
