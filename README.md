Native Keyboard
===============

> Every mobile app attempts to expand until it includes chat. Those applications which do not are replaced by ones which can.
>
> -- _[Luke Wroblewski](http://www.lukew.com/ff/entry.asp?1696)_


<img src="https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/raw/master/media/videos/iOS/messenger.gif" height="716px"/>&nbsp;&nbsp;&nbsp;
<img src="https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/raw/master/media/videos/Android/messenger.gif" height="716px"/>

_Videos of iOS and Android running the [included demo app](demo/index.html)._

## So it's just a fancy keyboard?
You're damn right it is! 👍😊

A cross platform WhatsApp / Messenger / Slack -style keyboard even. For _your_ Cordova app.

## Cool, but does it scale?
Lol.. wut?

## OK, let me try this..
Open a command prompt and do:

```
$ cordova create nativekeyboardtest
$ cd nativekeyboardtest
$ cordova plugin add cordova-plugin-native-keyboard
```

.. and for a nicer demo experience you'll also want to add these plugins:

```
$ cordova plugin add cordova-plugin-console
$ cordova plugin add cordova-plugin-actionsheet
```

.. now copy the contents of [our demo](demo/index.html) over `www/index.html`, and do one of these:

```
$ cordova run ios
$ cordova run android
```

## I'm no dummy, gimme details man!
ok ok - OK! The plugin is currently entirely focused on the messenger component, but this will extend into [other areas](https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/issues/1) in the future. With that being said, this is the current awesome API:

### `showMessenger`
The bare minimum you need to show the messenger and do something useful with the text a user typed is this (make sure you wait for `deviceready` to fire):

```js
NativeKeyboard.showMessenger({
  onSubmit: function(text) {
    console.log("The user typed: " + text);
  }
});
```

There are however __many__ options you can pass in to tweak the appearance and behavior:

|option|default|iOS|Android|description
|---|---|---|---|---
|`onSubmit`||yes|yes|A function invoked when the user submits his input. Receives the text as a single property. Make sure your page is UTF-8 encoded so Chinese and Emoji are rendered OK.
|`onKeyboardWillShow`||yes|no|A function invoked when the keyboard is about to pop up. Receives the height as a single property.
|`onKeyboardDidShow`||yes|yes|A function invoked when the keyboard popped up. Receives the height as a single property.
|`onKeyboardWillHide`||yes|no|A function invoked when the keyboard is about to close.
|`onKeyboardDidHide`||yes|yes|A function invoked when the keyboard closed.
|`onTextChanged`||yes|yes|A function invoked when any key is pressed, sends the entire text as response.
|`autoscrollElement`||yes|yes|Highly recommended to pass in if you want to replicate the behavior of the video's above (scroll down when the keyboard opens). Pass in the scrollable DOM element containing the messages, so something like `document.getElementById("messageList")`.
|`scrollToBottomAfterMessengerShows`||yes|yes|If `autoscrollElement` was set you can also make the list scroll down initially, when the messenger bar (without the keyboard popping up) is shown.
|`keepOpenAfterSubmit`|`false`|yes|yes|Setting this to `true` is like the video's above: the keyboard doesn't close upon submit.
|`animated`|`false`|yes|yes|Makes the messenger bar slide in from the bottom.
|`showKeyboard`|`false`|yes|yes|Open the keyboard when showing the messenger.
|`text`||yes|yes|The default text set in the messenger input bar.
|`textColor`|`#444444`|yes|yes|The color of the typed text.
|`placeholder`||yes|yes|Like a regular HTML input placeholder.
|`placeholderColor`|`#CCCCCC`|yes|yes|The color of the placeholder text.
|`backgroundColor`|`#F6F6F6`|yes|yes|The background color of the messenger bar.
|`textViewBackgroundColor`|`#F6F6F6`|yes|yes|The background color of the textview. Looks nicest on Android if it's the same color as the `backgroundColor` property.
|`textViewBorderColor`|`#666666`|yes|no|The border color of the textview.
|`maxChars`||yes|limited|Setting this > 0 will make a counter show up on iOS (and ignore superfluous input on Android, for now)
|`counterStyle`|"none"|yes|no|Options are: "none", "split", "countdown", "countdownreversed". Note that if `maxChars` is set, "none" will still show a counter.
|`type`|"default"|yes|no|Options are: "default", "decimalpad", "phonepad", "numberpad", "namephonepad", "number", "email", "twitter", "url", "alphabet", "search", "ascii"
|`appearance`|"default"|yes|no|Options are: "light", "dark".
|`secure`|`false`|yes|no|disables things like the Emoji keyboard and the Predicive text entry bar
|`leftButton`||yes|yes|See below
|`rightButton`||yes|yes|See below

#### leftButton
The button on the left is optional and can be used to for instance make a picture, grab a picture from the camera role, shoot a video, .. whatever you fancy, really as the implementation is entirely up to you.

As shown in the video's it's common to present these options as an ActionSheet, either [native](https://github.com/EddyVerbruggen/cordova-plugin-actionsheet) or a [HTML widget](https://ionicframework.com/docs/api/service/$ionicActionSheet/).

|option|default|iOS|Android|description
|---|---|---|---|---
|`type`||yes|limited|Either "text" (Android only currently), "fontawesome" or "ionicon".
|`value`||yes|yes|Depends on the `type`. Examples: for "text" use "Send", for "fontawesome" use "fa-battery-quarter", for "ionicon" use "\uf48a" (go to http://ionicons.com, right-click and inspect the icon and use the value you find in `:before`). Note that some fonticons are not supported as the embedded fonts in the plugin may lag behind a little. So try one of the older icons first.
|`textStyle`|"normal"|yes|yes|If `type` is "text" you can set this to either "normal", "bold" or "italic".
|`disabledWhenTextEntered`|`false`|yes|yes|Set to `true` to disable the button once text has been entered.
|`onPress`||yes|yes|A function invoked when the button is pressed. Use this button to prompt the user what he wants to do next by for instance rendering an ActionSheet.

#### rightButton
The button on the right is used to submit the entered text. You don't need to configure this at all if you're happy with the default "Send" label as the entered text itself will be emitted through the `onSubmit` callback.

|option|default|iOS|Android|description
|---|---|---|---|---
|`type`|"text"|yes|yes|Either "text", "fontawesome" or "ionicon".
|`value`|"Send"|yes|yes|See the description of `leftButton.value`.
|`textStyle`|"normal"|yes|yes|See the description of `leftButton.textStyle`.
|`onPress`||yes|yes|A function invoked when the button is pressed. Use this to for instance hide the messenger entirely after text was entered by calling `NativeKeyboard.hideMessenger()`.


### `hideMessenger`
It's likely your app only has 1 one page where you want to show the messenger, so you want to hide it when the user navigates away. You can choose to do this either animated (a quick slide down animation) or not.

```js
NativeKeyboard.hideMessenger({
  animated: true // default false
});
```

### `showMessengerKeyboard`
What if you have previously have shown the messenger and the user dismissed its keyboard, but you want to programmatically
pop up the keyboard again? Use this:

```js
NativeKeyboard.showMessengerKeyboard(
    // these functions are optional
    function() { console.log('ok') },
    function(err) { console.log(err)}
);
```

### `hideMessengerKeyboard`
And if you want to programmatically hide the keyboard (but not the messenger bar), use this:

```js
NativeKeyboard.hideMessengerKeyboard(
    // these functions are optional
    function() { console.log('ok') },
    function(err) { console.log(err)}
);
```

### `updateMessenger`
Manipulate the messenger while it's open. For instance if you want to update the text programmatically based on what the user typed (by responding to `onTextChanged` events).

|option|type|iOS|Android|description
|---|---|---|---|---
|`text`|`string`|yes|yes|Replace the messenger's text by this. The current text remains if omitted.
|`caretIndex`|`number`|yes|yes|Position the cursor anywhere in the text range. Defaults to the end of the text.
|`showKeyboard`|`boolean`|yes|yes|If `false` or omitted no changes to the keyboard state are made.

```js
NativeKeyboard.updateMessenger(
    {
      text: "Text updated! ", // added a space so the user can continue typing
      caretIndex: 5,
      showKeyboard: true
    },
    function() { console.log('updated ok') },
    function(err) { console.log(err)}
);
```

## A note on iPhone X (and other iOS devices with rounded screens)
Update this plugin to at least 1.5.0, and add [`viewport-fit=cover` to your viewport](https://github.com/EddyVerbruggen/cordova-plugin-native-keyboard/blob/84fa7ce962f1b56cc71b1d1f2454c46ba3b8aca7/demo/index.html#L6). 

## I like it, hook me up!
This plugin has been a BEAST to implement and its maintenance is killing me already so I need to make this a commercial offering (with a __free trial__, see below) to keep it afloat. If you have a compelling reason to not pay for an unlocked version let me know and we'll work something out.

* Look up the ID of the app you want to use the plugin with - you can find it at the top of config.xml and is something like `io.cordova.hellocordova` (if you have a different staging ID, or iOS and Android ID's are different just send me all of those and __you'll get multiple license codes and pay for only one__).
* Send a one-time fee of USD 199 (or EUR 185) to [my PayPal account](https://www.paypal.me/EddyVerbruggen/199usd) and make sure to include your app ID. Want to use a bankaccount instead? No problem, just contact me at eddyverbruggen@gmail.com for details.
* You'll quickly receive a license key (and instructions) which you can use to install the plugin.
* You can now forever use this version and any future version of this plugin for this app without restrictions.

## I heard about a trial!?
ALL features are available without a license, but you'll be restricted to 5 minutes of usage. Just indefinitely kill and relaunch the app if you need more time ;)

## Can you remove the license check for my prototype apps?
Sure, just add the word 'prototype' (case insensitive) anywhere in your packageid. Example: 'com.mycompany.myclientapp-PROTOTYPE' or 'com.mycompany.prototypes.myclientapp'.