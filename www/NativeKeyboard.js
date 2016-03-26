
function NativeKeyboard() {
}

NativeKeyboard.prototype.hideMessenger = function(options, onSuccess) {
  var opts = options || {};
  cordova.exec(null, null, "NativeKeyboard", "hideMessenger", [opts]);
};

NativeKeyboard.prototype.showMessenger = function(options, onSuccess) {
  var opts = options || {};
  var onSuccessInternal = function(res) {
    if (res.messengerRightButtonPressed === true) {
      if (typeof opts.rightButton.callback == 'function') {
        opts.rightButton.callback();
      }
    }
    if (res.keyboardDidShow === true && res.keyboardHeight) {
      onSuccess(res);
    } else if (res.keyboardWillHide === true) {
      onSuccess(res);
    } else if (res.text !== undefined) {
      onSuccess(res);
    } else if (res.contentHeightDiff !== undefined && res.contentHeightDiff !== 0) {
      onSuccess(res);
    } else if (res.messengerLeftButtonPressed === true) {
      if (typeof opts.leftButton.callback == 'function') {
        opts.leftButton.callback();
      }
    } else {
      console.log('JS Unexpected plugin result: ' + JSON.stringify(res));
    }
  };

  cordova.exec(onSuccessInternal, null, "NativeKeyboard", "showMessenger", [opts]);
};
               
NativeKeyboard.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.NativeKeyboard = new NativeKeyboard();
  return window.NativeKeyboard;
};

cordova.addConstructor(NativeKeyboard.install);
