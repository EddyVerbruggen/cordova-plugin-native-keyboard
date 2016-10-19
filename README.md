Native Keyboard
===============

This plugin aims to solve common keyboard problems encountered with Cordova / PhoneGap apps.
The messenger component (see screenshots) is ready for production, but this plugin will have
more tricks up its sleeve. I'll document those once they're ready for primetime as well.

## Screenshots
Messenger component

### iOS
<img src="screenshots/iOS/messenger-1.png?v=2" width="350px"/>&nbsp;&nbsp;&nbsp;
<img src="screenshots/iOS/messenger-2.png?v=2" width="350px"/>

### Android
<img src="screenshots/Android/messenger-1.png?v=2" width="350px"/>&nbsp;&nbsp;&nbsp;
<img src="screenshots/Android/messenger-2.png?v=2" width="350px"/>


## I wanna try it!
```
$ cordova create nativekeyboardtest
$ cd nativekeyboardtest
$ cordova plugin add cordova-plugin-nativekeyboard
```

Now copy the contents of [our demo](demo/index.html) over `www/index.html`, and do one of these:

```
$ cordova run ios
$ cordova run android
```

ALL features are available, but you'll be restricted to 5 minutes of usage.
Just kill and relaunch the app if you need more time ;)

Tweak the `showMessenger()` method to play with its behavior and appearance.

## I like it, hook me up!
This plugin has been a BEAST to implement and its maintenance is killing me already
so I need to make this a commercial offering to keep it afloat. If you have a compelling
reason to not pay for an unlocked version let me know and we'll try to work out something.

* Look up the ID of the app you want to use the plugin with - you can find it at the top of config.xml and is something like `io.cordova.hellocordova`.
* Send a __one-time__ fee of $ 199 to [my PayPal account](https://www.paypal.me/EddyVerbruggen/199usd) and make sure to include your app ID.
* You'll quickly receive a license key (and instructions) which you can use to install the plugin.
* You can now forever use this version and any future version of this plugin for this app without restrictions.