Native Keyboard
===============

<img src="nativekeyboard.png" width="80px"/>

### Screenshots
<img src="screenshots/messenger-1.png" width="350px"/>&nbsp;&nbsp;&nbsp;
<img src="screenshots/messenger-2.png" width="350px"/>

### Quickstart
Throw these in a Terminal window:

```
cordova create NativeKeyboardTest
cd NativeKeyboardTest
cordova platform add ios
cordova plugin add ../../cordova-plugin-native-keyboard/cordova-plugin-native-keyboard
cp {{ path to }}/cordova-plugin-native-keyboard/demo/index.html www/
cordova run ios
```

Now you'll be able to play with the messenger component of this plugin. See `demo/index.html` for all the available properties.