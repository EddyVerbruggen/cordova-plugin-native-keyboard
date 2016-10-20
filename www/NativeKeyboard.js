
function NativeKeyboard() {
}

var isIOS = (/iPad|iPhone|iPod/.test(navigator.userAgent));

if (isIOS) {
  document.addEventListener('focusin', function (e) {
    // - you want this only on if some data-customkeyboard property is set.. or consider a global pref
    // - note that you should not mix with and without nk on one page currently
    if (!e.target.getAttribute('data-nativekeyboard') || e.target.getAttribute('data-nativekeyboard') == "false") {
      return;
    }
    e.preventDefault();
    e.stopPropagation();

    var elem = document.activeElement;
    if (elem) {
      document.activeElement.blur();
    }

    var success = function (e1) {
      e.target.value = e1;
    };

    NativeKeyboard.prototype._showKeyboard(e.target, e.target.value, success);
  });
}

NativeKeyboard.prototype.editText = function (selector) {
  var success = function (e) {
    selector.innerText = e;
  };
  NativeKeyboard.prototype._showKeyboard(selector, selector.innerText, success);
};

NativeKeyboard.prototype.hideMessenger = function (options, onSuccess, onError) {
  var opts = options || {};
  var onErrorInternal = function (res) {
    console.log("Error in hideMessenger: " + res);
    if (onError) {
      onError(res);
    }
  };
  cordova.exec(onSuccess, onError, "NativeKeyboard", "hideMessenger", [opts]);
};

NativeKeyboard.prototype.showMessenger = function (options, onSuccess, onError) {
  var opts = options || {};
  if (opts.autoscrollElement) {
    // used in iOS
    opts.scrollToBottomAfterKeyboardShows = true;
  }
  if (opts.scrollToBottomAfterKeyboardShows && opts.scrollToBottomAfterMessengerShows === undefined) {
    opts.scrollToBottomAfterMessengerShows = true;
  }
  if (opts.scrollToBottomAfterMessengerShows && opts.scrollToBottomAfterKeyboardShows) {
    scrollTo(opts.autoscrollElement, opts.autoscrollElement.scrollHeight);
  }
  var onSuccessInternal = function (res) {
    if (res.messengerRightButtonPressed === true) {
      if (typeof opts.rightButton.onPress == "function") {
        opts.rightButton.onPress();
      }
    }
    if (res.ready) {
      if (typeof onSuccess == "function") {
        onSuccess();
      }
    } else if (res.keyboardDidShow === true) {
      if (opts.autoscrollElement) {
        // on iOS we deal with this in native code - but that sometimes breaks, so using this fallback xplatform
        scrollTo(opts.autoscrollElement, opts.autoscrollElement.scrollHeight);
      }
      if (typeof opts.onKeyboardDidShow == "function") {
        opts.onKeyboardDidShow(res.keyboardHeight);
      }
    } else if (res.keyboardDidHide === true) {
      if (typeof opts.onKeyboardDidHide == "function") {
        opts.onKeyboardDidHide();
      }
    } else if (res.text !== undefined) {
      if (typeof opts.onSubmit == "function") {
        opts.onSubmit(res.text);
      } else {
        console.log("Received " + res.text + ", pass in an 'onSubmit' function to catch it in your app.");
      }
    } else if (res.contentHeightDiff !== undefined && res.contentHeightDiff !== 0) {
      if (typeof opts.onContentHeightChanged == "function") {
        opts.onContentHeightChanged(res);
      }
    } else if (res.messengerLeftButtonPressed === true) {
      if (typeof opts.leftButton.onPress == 'function') {
        opts.leftButton.onPress();
      }
    } else {
      console.log('JS Unexpected plugin result: ' + JSON.stringify(res));
    }
  };
  var onErrorInternal = function (res) {
    console.log("Error in showMessenger: " + res);
    if (onError) {
      onError(res);
    }
  };
  cordova.exec(onSuccessInternal, onErrorInternal, "NativeKeyboard", "showMessenger", [opts]);
};

NativeKeyboard.prototype._showKeyboard = function (selector, text, onTextUpdate) {
  var isTextarea = "textarea" === selector.tagName.toLowerCase();
  var att = selector.getAttribute("data-nativekeyboard");
  var opts = null;
  if (att.indexOf('{') === 0) {
    // in case the value is '{[options]}'
    opts = JSON.parse(att);
  } else if (typeof window[att] == 'function') {
    // in case the value is 'someFunction'
    opts = eval(window[att]());
  } else {
    // in case the value is 'someFunction([options])'
    opts = eval(att);
  }
  if (typeof opts != 'object') {
    opts = {};
  }

  opts.text = text;
  // if no type is passed the html5 type is used, but if it's not valid html5 (twitter/decimal) it falls back to text
  opts.type = opts.type || selector.type.toLowerCase();
  opts.maxlength = opts.maxlength || selector.getAttribute('maxlength') || 0;
  opts.caretColor = opts.caretColor || '#007AFF'; // default is iOS blue
  var css = window.getComputedStyle(selector);
  opts.verticalAlign = css.verticalAlign;
  opts.textAlign = css.textAlign;
  opts.offsetTop = window.pageYOffset;
  opts.font = "font-family:" + css.fontFamily + ";font-size:" + css.fontSize + ";font-weight:" + css.fontWeight + ";font-style:" + css.fontStyle;
  var viewportOffset = selector.getBoundingClientRect();
  var top = selector.scrollTop;
  var left = selector.scrollLeft;

  opts.boxSizing = css.boxSizing;
  opts.box = opts.box || {
        left: viewportOffset.left,
        top: viewportOffset.top,
        width: css.width,
        height: css.height // TODO use this for line-height as well when not textarea and vertical-align:middle
      };
//  opts.type = 'decimal';

  opts.padding = opts.padding || {
        top: css.paddingTop,
        right: css.paddingRight,
        bottom: css.paddingBottom,
        left: css.paddingLeft
      };

  // compsensate for a Safari textarea issue
  var compensateLeft = isTextarea ? 0 : 0;
  var compensateTop = isTextarea ? 1 : 0; // TODO 1 - met '1px' string gaat dat fout
  opts.margin = opts.margin || {
        top: parseInt(css.marginTop) + compensateTop,
        right: css.marginRight,
        bottom: css.marginBottom,
        left: parseInt(css.marginLeft) + compensateLeft
      };

  opts.border = opts.border || {
        top: css.borderTopWidth,
        right: css.borderRightWidth,
        bottom: css.borderBottomWidth,
        left: css.borderLeftWidth
      };

  opts.borderRadius = opts.borderRadius || css.borderRadius;
  opts.lineHeight = opts.lineHeight || css.lineHeight;

  var onSuccess = function (res) {
    if (res.textFieldDidEndEditing === true) {
      // if text was entered (and more than the textfield width) scroll left
      selector.scrollLeft = 0;
    }

    if (res.text !== undefined) {
      onTextUpdate(res.text);
      // to make the html input scroll to the right when text is entered:
      if (!isTextarea) {
        selector.scrollLeft = selector.scrollWidth;
        // we also do this onfocus for that extra native feel, see further down
      }
    } else if (res.returnKeyPressed === true) {
      var returnKey = opts.returnKey;
      if (returnKey && typeof returnKey.onPress == 'function') {
        returnKey.onPress();
      }
      // if text was entered (and more than the textfield width) scroll left
      if (!isTextarea) {
        selector.scrollLeft = 0;
      }
    } else if (res.buttonIndex !== undefined) {
      var but = opts.accessorybar.buttons[res.buttonIndex];
      if (but.close === true) {
        NativeKeyboard.prototype.hideKeyboard();
      }
      if (typeof but.callback == 'function') {
        but.callback();
      }
    } else {
      console.log('JS Unexpected plugin result: ' + JSON.stringify(res));
    }
  };

  // if text was already entered (and more than the textfield width) scroll right
  if (!isTextarea) {
    selector.scrollLeft = selector.scrollWidth;
  }

  document.addEventListener("touchend", NativeKeyboard.prototype.touchHandler, false);

  cordova.exec(onSuccess, null, "NativeKeyboard", "show", [opts]);
};

NativeKeyboard.prototype.hideKeyboard = function () {
  cordova.exec(null, null, "NativeKeyboard", "hide", []);
  document.removeEventListener("touchend", NativeKeyboard.prototype.touchHandler);
};

NativeKeyboard.prototype.touchHandler = function (event) {
  var tag = event.target.tagName.toLowerCase();
  // hide, unless we're going to a new input element
  if (tag !== 'input' && tag !== 'textarea') {
    NativeKeyboard.prototype.hideKeyboard();
  }
};

NativeKeyboard.prototype.updateInput = function (e) {
  var val = NativeKeyboard.prototype.activeInput.value;
  if (e.text === '') {
    val = val.substring(0, val.length - 1);
  } else {
    val += e.text;
  }
  NativeKeyboard.prototype.activeInput.value = val;
};

NativeKeyboard.prototype.activeInput = null;

NativeKeyboard.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.NativeKeyboard = new NativeKeyboard();
  return window.NativeKeyboard;
};


Math.easeInOutQuad = function (t, b, c, d) {
  t /= d/2;
  if (t < 1) {
    return c/2*t*t + b
  }
  t--;
  return -c/2 * (t*(t-2) - 1) + b;
};

Math.easeInCubic = function(t, b, c, d) {
  var tc = (t/=d)*t*t;
  return b+c*(tc);
};

Math.inOutQuintic = function(t, b, c, d) {
  var ts = (t/=d)*t,
      tc = ts*t;
  return b+c*(6*tc*ts + -15*ts*ts + 10*tc);
};

// requestAnimationFrame for Smart Animating http://goo.gl/sx5sts
var requestAnimFrame = (function(){
  return  window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || function( callback ){ window.setTimeout(callback, 1000 / 60); };
})();

function scrollTo(elem, to, callback, duration) {
  // because it's so fucking difficult to detect the scrolling element, just move them all
  function move(amount) {
    elem.scrollTop = amount;
  }
  function position() {
    return elem.scrollTop;
  }
  var start = position(),
      change = to - start,
      currentTime = 0,
      increment = 20;
  duration = (typeof(duration) === 'undefined') ? 500 : duration;
  var animateScroll = function() {
    // increment the time
    currentTime += increment;
    // find the value with the quadratic in-out easing function
    var val = Math.easeInOutQuad(currentTime, start, change, duration);
    // move the document.body
    move(val);
    // do the animation unless its over
    if (currentTime < duration) {
      requestAnimFrame(animateScroll);
    } else {
      if (callback && typeof(callback) === 'function') {
        // the animation is done so lets callback
        callback();
      }
    }
  };
  animateScroll();
}
cordova.addConstructor(NativeKeyboard.install);
