
function NativeKeyboard() {
}

document.addEventListener('focusin', function(e) {
  // - you want this only on if some data-customkeyboard property is set.. or consider a global pref
  // - note that you should not mix with and without nk on one page currently
  if (!e.target.getAttribute('data-nativekeyboard') || e.target.getAttribute('data-nativekeyboard') == "false") {
    return;
  }
//                          return;
  e.preventDefault();
  e.stopPropagation();

  var elem = document.activeElement;
  if (elem) {
    document.activeElement.blur();
  }
                          
  var success = function(e1) {
//    console.log("JS ---- input: " + e1);
    e.target.value = e1;
  };

//  console.log("JS ----- calling show A from tag " + e.target.tagName);
  NativeKeyboard.prototype._showKeyboard(e.target, e.target.value, success);
});

NativeKeyboard.prototype.editText = function(selector) {
  var success = function(e) {
//    console.log("JS editText: " + e);
    selector.innerText = e;
  };
//  console.log("JS ----- calling show B");
  NativeKeyboard.prototype._showKeyboard(selector, selector.innerText, success);
};

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

NativeKeyboard.prototype._showKeyboard = function(selector, text, onTextUpdate) {
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
  opts.font = "font-family:"+css.fontFamily+";font-size:"+css.fontSize+";font-weight:"+css.fontWeight+";font-style:"+css.fontStyle;
  var viewportOffset = selector.getBoundingClientRect();
  var top = selector.scrollTop;
  var left = selector.scrollLeft;

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
  var compensateLeft = "textarea" === selector.tagName.toLowerCase() ? 0 : 0;
  var compensateTop = "textarea" === selector.tagName.toLowerCase() ? 1 : 0; // TODO 1 - met '1px' string gaat dat fout
//               console.log("css.marginLeft: " + parseInt(css.marginLeft));
//               console.log(parseInt(css.marginLeft) + compensateLeft);
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
               
//  console.log("margin left: " + css.marginLeft);
//  console.log("border left: " + css.borderLeftWidth);
//  console.log("padding left: " + css.paddingLeft);

  opts.lineHeight = opts.lineHeight || css.lineHeight;
//  console.log("JS lineHeight: " + opts.lineHeight);

  var onSuccess = function(res) {
    if (res.text !== undefined) {
      onTextUpdate(res.text);
    } else if (res.returnKeyPressed === true) {
      var returnKey = opts.returnKey;
      if (returnKey && typeof returnKey.onPress == 'function') {
        returnKey.onPress();
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

  document.addEventListener("touchend", NativeKeyboard.prototype.touchHandler, false);

  cordova.exec(onSuccess, null, "NativeKeyboard", "show", [opts]);
};

NativeKeyboard.prototype.hideKeyboard = function() {
  cordova.exec(null, null, "NativeKeyboard", "hide", []);
  document.removeEventListener("touchend", NativeKeyboard.prototype.touchHandler);
};

NativeKeyboard.prototype.touchHandler = function(event) {
  var tag = event.target.tagName.toLowerCase();
  // hide, unless we're going to a new input element
  if (tag !== 'input' && tag !== 'textarea') {
    NativeKeyboard.prototype.hideKeyboard();
  }
};

NativeKeyboard.prototype.updateInput = function(e){
  var val = NativeKeyboard.prototype.activeInput.value;
  if (e.text === '') {
    val = val.substring(0, val.length-1);
  } else {
    val += e.text;
  }
  NativeKeyboard.prototype.activeInput.value = val;
};
               
NativeKeyboard.prototype.activeSelector = null;
NativeKeyboard.prototype.activeInput = null;
               
NativeKeyboard.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.NativeKeyboard = new NativeKeyboard();
  return window.NativeKeyboard;
};

cordova.addConstructor(NativeKeyboard.install);
