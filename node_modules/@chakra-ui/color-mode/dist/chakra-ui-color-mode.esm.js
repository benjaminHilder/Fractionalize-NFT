import { useSafeLayoutEffect } from '@chakra-ui/hooks';
import { isBrowser, __DEV__, noop } from '@chakra-ui/utils';
import * as React from 'react';

function _extends() {
  _extends = Object.assign || function (target) {
    for (var i = 1; i < arguments.length; i++) {
      var source = arguments[i];

      for (var key in source) {
        if (Object.prototype.hasOwnProperty.call(source, key)) {
          target[key] = source[key];
        }
      }
    }

    return target;
  };

  return _extends.apply(this, arguments);
}

var classNames = {
  light: "chakra-ui-light",
  dark: "chakra-ui-dark"
};
function getColorModeUtils(options) {
  if (options === void 0) {
    options = {};
  }

  var _options = options,
      _options$preventTrans = _options.preventTransition,
      preventTransition = _options$preventTrans === void 0 ? true : _options$preventTrans;
  var utils = {
    setDataset: function setDataset(value) {
      var cleanup = preventTransition ? utils.preventTransition() : undefined;
      document.documentElement.dataset.theme = value;
      document.documentElement.style.colorScheme = value;
      cleanup == null ? void 0 : cleanup();
    },
    setClassName: function setClassName(dark) {
      document.body.classList.add(dark ? classNames.dark : classNames.light);
      document.body.classList.remove(dark ? classNames.light : classNames.dark);
    },
    query: function query() {
      return window.matchMedia("(prefers-color-scheme: dark)");
    },
    getSystemTheme: function getSystemTheme(fallback) {
      var _utils$query$matches;

      var dark = (_utils$query$matches = utils.query().matches) != null ? _utils$query$matches : fallback === "dark";
      return dark ? "dark" : "light";
    },
    addListener: function addListener(fn) {
      var mql = utils.query();

      var listener = function listener(e) {
        fn(e.matches ? "dark" : "light");
      };

      mql.addEventListener("change", listener);
      return function () {
        return mql.removeEventListener("change", listener);
      };
    },
    preventTransition: function preventTransition() {
      var css = document.createElement("style");
      css.appendChild(document.createTextNode("*{-webkit-transition:none!important;-moz-transition:none!important;-o-transition:none!important;-ms-transition:none!important;transition:none!important}"));
      document.head.appendChild(css);
      return function () {

        (function () {
          return window.getComputedStyle(document.body);
        })(); // wait for next tick


        requestAnimationFrame(function () {
          requestAnimationFrame(function () {
            document.head.removeChild(css);
          });
        });
      };
    }
  };
  return utils;
}

var STORAGE_KEY = "chakra-ui-color-mode";
function createLocalStorageManager(key) {
  return {
    ssr: false,
    type: "localStorage",
    get: function get(init) {
      if (!isBrowser) return init;
      var value;

      try {
        value = localStorage.getItem(key) || init;
      } catch (e) {// no op
      }

      return value || init;
    },
    set: function set(value) {
      try {
        localStorage.setItem(key, value);
      } catch (e) {// no op
      }
    }
  };
}
var localStorageManager = createLocalStorageManager(STORAGE_KEY);

function parseCookie(cookie, key) {
  var match = cookie.match(new RegExp("(^| )" + key + "=([^;]+)"));
  return match == null ? void 0 : match[2];
}

function createCookieStorageManager(key, cookie) {
  return {
    ssr: !!cookie,
    type: "cookie",
    get: function get(init) {
      if (cookie) return parseCookie(cookie, key);
      if (!isBrowser) return init;
      return parseCookie(document.cookie, key) || init;
    },
    set: function set(value) {
      document.cookie = key + "=" + value + "; max-age=31536000; path=/";
    }
  };
}
var cookieStorageManager = createCookieStorageManager(STORAGE_KEY);
var cookieStorageManagerSSR = function cookieStorageManagerSSR(cookie) {
  return createCookieStorageManager(STORAGE_KEY, cookie);
};

var ColorModeContext = /*#__PURE__*/React.createContext({});

if (__DEV__) {
  ColorModeContext.displayName = "ColorModeContext";
}
/**
 * React hook that reads from `ColorModeProvider` context
 * Returns the color mode and function to toggle it
 */


function useColorMode() {
  var context = React.useContext(ColorModeContext);

  if (context === undefined) {
    throw new Error("useColorMode must be used within a ColorModeProvider");
  }

  return context;
}

function getTheme(manager, fallback) {
  return manager.type === "cookie" && manager.ssr ? manager.get(fallback) : fallback;
}
/**
 * Provides context for the color mode based on config in `theme`
 * Returns the color mode and function to toggle the color mode
 */


function ColorModeProvider(props) {
  var value = props.value,
      children = props.children,
      _props$options = props.options;
  _props$options = _props$options === void 0 ? {} : _props$options;
  var useSystemColorMode = _props$options.useSystemColorMode,
      initialColorMode = _props$options.initialColorMode,
      disableTransitionOnChange = _props$options.disableTransitionOnChange,
      _props$colorModeManag = props.colorModeManager,
      colorModeManager = _props$colorModeManag === void 0 ? localStorageManager : _props$colorModeManag;
  var defaultColorMode = initialColorMode === "dark" ? "dark" : "light";

  var _React$useState = React.useState(function () {
    return getTheme(colorModeManager, defaultColorMode);
  }),
      colorMode = _React$useState[0],
      rawSetColorMode = _React$useState[1];

  var _React$useState2 = React.useState(function () {
    return getTheme(colorModeManager);
  }),
      resolvedColorMode = _React$useState2[0],
      setResolvedColorMode = _React$useState2[1];

  var _React$useMemo = React.useMemo(function () {
    return getColorModeUtils({
      preventTransition: disableTransitionOnChange
    });
  }, [disableTransitionOnChange]),
      getSystemTheme = _React$useMemo.getSystemTheme,
      setClassName = _React$useMemo.setClassName,
      setDataset = _React$useMemo.setDataset,
      addListener = _React$useMemo.addListener;

  var resolvedValue = initialColorMode === "system" && !colorMode ? resolvedColorMode : colorMode;
  var setColorMode = React.useCallback(function (value) {
    //
    var resolved = value === "system" ? getSystemTheme() : value;
    rawSetColorMode(resolved);
    setClassName(resolved === "dark");
    setDataset(resolved);
    colorModeManager.set(resolved);
  }, [colorModeManager, getSystemTheme, setClassName, setDataset]);
  useSafeLayoutEffect(function () {
    if (initialColorMode === "system") {
      setResolvedColorMode(getSystemTheme());
    } // eslint-disable-next-line react-hooks/exhaustive-deps

  }, []);
  useSafeLayoutEffect(function () {
    var managerValue = colorModeManager.get();

    if (managerValue) {
      setColorMode(managerValue);
      return;
    }

    if (initialColorMode === "system") {
      setColorMode("system");
      return;
    }

    setColorMode(defaultColorMode); //
  }, [colorModeManager, defaultColorMode, initialColorMode, getSystemTheme]);
  var toggleColorMode = React.useCallback(function () {
    setColorMode(resolvedValue === "dark" ? "light" : "dark");
  }, [resolvedValue, setColorMode]);
  React.useEffect(function () {
    if (!useSystemColorMode) return;
    return addListener(setColorMode);
  }, [useSystemColorMode, addListener, setColorMode]); // presence of `value` indicates a controlled context

  var context = React.useMemo(function () {
    return {
      colorMode: value != null ? value : resolvedValue,
      toggleColorMode: value ? noop : toggleColorMode,
      setColorMode: value ? noop : setColorMode
    };
  }, [resolvedValue, toggleColorMode, setColorMode, value]);
  return /*#__PURE__*/React.createElement(ColorModeContext.Provider, {
    value: context
  }, children);
}

if (__DEV__) {
  ColorModeProvider.displayName = "ColorModeProvider";
}
/**
 * Locks the color mode to `dark`, without any way to change it.
 */


var DarkMode = function DarkMode(props) {
  var context = React.useMemo(function () {
    return {
      colorMode: "dark",
      toggleColorMode: noop,
      setColorMode: noop
    };
  }, []);
  return /*#__PURE__*/React.createElement(ColorModeContext.Provider, _extends({
    value: context
  }, props));
};

if (__DEV__) {
  DarkMode.displayName = "DarkMode";
}
/**
 * Locks the color mode to `light` without any way to change it.
 */


var LightMode = function LightMode(props) {
  var context = React.useMemo(function () {
    return {
      colorMode: "light",
      toggleColorMode: noop,
      setColorMode: noop
    };
  }, []);
  return /*#__PURE__*/React.createElement(ColorModeContext.Provider, _extends({
    value: context
  }, props));
};

if (__DEV__) {
  LightMode.displayName = "LightMode";
}
/**
 * Change value based on color mode.
 *
 * @param light the light mode value
 * @param dark the dark mode value
 *
 * @example
 *
 * ```js
 * const Icon = useColorModeValue(MoonIcon, SunIcon)
 * ```
 */


function useColorModeValue(light, dark) {
  var _useColorMode = useColorMode(),
      colorMode = _useColorMode.colorMode;

  return colorMode === "dark" ? dark : light;
}

var VALID_VALUES = new Set(["dark", "light", "system"]);
/**
 * runtime safe-guard against invalid color mode values
 */

function normalize(initialColorMode) {
  var value = initialColorMode;
  if (!VALID_VALUES.has(value)) value = "light";
  return value;
}

function getScriptSrc(props) {
  if (props === void 0) {
    props = {};
  }

  var _props = props,
      _props$initialColorMo = _props.initialColorMode,
      initialColorMode = _props$initialColorMo === void 0 ? "light" : _props$initialColorMo,
      _props$type = _props.type,
      type = _props$type === void 0 ? "localStorage" : _props$type,
      _props$storageKey = _props.storageKey,
      key = _props$storageKey === void 0 ? "chakra-ui-color-mode" : _props$storageKey; // runtime safe-guard against invalid color mode values

  var init = normalize(initialColorMode);
  var isCookie = type === "cookie";
  var cookieScript = "(function(){try{var a=function(o){var l=\"(prefers-color-scheme: dark)\",v=window.matchMedia(l).matches?\"dark\":\"light\",e=o===\"system\"?v:o,d=document.documentElement,m=document.body,i=\"chakra-ui-light\",n=\"chakra-ui-dark\",s=e===\"dark\";return m.classList.add(s?n:i),m.classList.remove(s?i:n),d.style.colorScheme=e,d.dataset.theme=e,e},u=a,h=\"" + init + "\",r=\"" + key + "\",t=document.cookie.match(new RegExp(\"(^| )\".concat(r,\"=([^;]+)\"))),c=t?t[2]:null;c?a(c):document.cookie=\"\".concat(r,\"=\").concat(a(h),\"; max-age=31536000; path=/\")}catch(a){}})();\n  ";
  var localStorageScript = "(function(){try{var a=function(c){var v=\"(prefers-color-scheme: dark)\",h=window.matchMedia(v).matches?\"dark\":\"light\",r=c===\"system\"?h:c,o=document.documentElement,s=document.body,l=\"chakra-ui-light\",d=\"chakra-ui-dark\",i=r===\"dark\";return s.classList.add(i?d:l),s.classList.remove(i?l:d),o.style.colorScheme=r,o.dataset.theme=r,r},n=a,m=\"" + init + "\",e=\"" + key + "\",t=localStorage.getItem(e);t?a(t):localStorage.setItem(e,a(m))}catch(a){}})();\n  ";
  var fn = isCookie ? cookieScript : localStorageScript;
  return ("!" + fn).trim();
}
function ColorModeScript(props) {
  if (props === void 0) {
    props = {};
  }

  return /*#__PURE__*/React.createElement("script", {
    id: "chakra-script",
    dangerouslySetInnerHTML: {
      __html: getScriptSrc(props)
    }
  });
}

export { ColorModeContext, ColorModeProvider, ColorModeScript, DarkMode, LightMode, STORAGE_KEY, cookieStorageManager, cookieStorageManagerSSR, createCookieStorageManager, createLocalStorageManager, getScriptSrc, localStorageManager, useColorMode, useColorModeValue };
