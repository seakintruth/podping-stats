/*** isMobileBinding is from ***/
/*** https://github.com/g3rv4/mobileDetect/blob/master/www/js/mobile.js ***/
var isMobileBinding = new Shiny.InputBinding();
$.extend(isMobileBinding, {
  find: function(scope) {
    return $(scope).find(".mobile-element");
    callback();
  },
  getValue: function(el) {
    return /((iPhone)|(iPod)|(iPad)|(iphone)|(ipod)|(ipad)|(Android)|(android)|(BlackBerry))/.test(navigator.userAgent)
  },
  setValue: function(el, value) {
  },
  subscribe: function(el, callback) {
  },
  unsubscribe: function(el) {
  }
});

var isMobileIosBinding = new Shiny.InputBinding();
$.extend(isMobileIosBinding, {
  find: function(scope) {
    return $(scope).find(".mobile-element");
    callback();
  },
  getValue: function(el) {
    return /((iPhone)|(iPod)|(iPad)|(iphone)|(ipod)|(ipad))/.test(navigator.userAgent)
  },
  setValue: function(el, value) {
  },
  subscribe: function(el, callback) {
  },
  unsubscribe: function(el) {
  }
});

var isMobileAndroidBinding = new Shiny.InputBinding();
$.extend(isMobileAndroidBinding, {
  find: function(scope) {
    return $(scope).find(".mobile-element");
    callback();
  },
  getValue: function(el) {
    return /((Android)|(android))/.test(navigator.userAgent)
  },
  setValue: function(el, value) {
  },
  subscribe: function(el, callback) {
  },
  unsubscribe: function(el) {
  }
});
Shiny.inputBindings.register(isMobileBinding);
Shiny.inputBindings.register(isMobileIosBinding);
Shiny.inputBindings.register(isMobileAndroidBinding);