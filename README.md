Native Keyboard
===============

<img src="nativekeyboard.png" width="80px"/>

__March 22 '16__: Work in progress. This is a huge effort to get right so please be patient. Once it's done you will be able to fi. hide the keyboard accessory bar, or add a custom item to it. Or trigger any of the (about) 12 different native keyboard types the iOS SDK has to offer.

__March 26 '16__: Still work in progress, but the messenger component is nearing completion. Check out the screenshots below. 

__April 2 '16__: Nearing completion - [please join the BETA TEST here](https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/issues/1)!

__April 8 '16__: Fixed a few important issues. Should be a lot better now. [Update 0.2.0 posted in the BETA TEST issue!](https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/issues/1)

## Screenshots
<img src="screenshots/messenger-1.png" width="350px"/>&nbsp;&nbsp;&nbsp;
<img src="screenshots/messenger-2.png" width="350px"/>

## Quickstart
Throw these in a Terminal window:

```
cordova create NativeKeyboardTest
cd NativeKeyboardTest
cordova platform add ios
cordova plugin add ../../cordova-plugin-native-keyboard/cordova-plugin-native-keyboard
cp ../../cordova-plugin-native-keyboard/cordova-plugin-native-keyboard/demo/index.html www/
cordova run ios
```

See `demo/index.html` for all the available methods and properties.