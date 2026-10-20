// Language: German and English. The page's HTML carries the English text, so
// it reads without JavaScript; this swaps every [data-i18n] node (text) and
// [data-i18n-attr] ("attr:key;attr:key") to the chosen language. The choice is
// kept in localStorage ('kalorat_lang', as on the old page); the first visit
// follows the browser.
(function () {
  'use strict';
  var KEY = 'kalorat_lang';
  var dict = window.KALORAT_STRINGS;
  var en = {};

  function stored() { try { return localStorage.getItem(KEY); } catch (_) { return null; } }
  function store(l) { try { localStorage.setItem(KEY, l); } catch (_) {} }

  function initial() {
    var s = stored();
    if (s === 'de' || s === 'en') return s;
    var langs = navigator.languages || [navigator.language || 'en'];
    for (var i = 0; i < langs.length; i++) {
      var l = String(langs[i]).toLowerCase();
      if (l.indexOf('de') === 0) return 'de';
      if (l.indexOf('en') === 0) return 'en';
    }
    return 'en';
  }

  // Remember the English text the HTML ships with, so switching back needs no copy of it.
  function capture() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      en[el.getAttribute('data-i18n')] = el.innerHTML;
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(function (el) {
      el.getAttribute('data-i18n-attr').split(';').forEach(function (pair) {
        var p = pair.split(':');
        en[p[1]] = el.getAttribute(p[0]);
      });
    });
    en['meta.title'] = document.title;
  }

  function t(lang, key) {
    if (lang === 'en') return en[key] != null ? en[key] : (dict.en && dict.en[key]);
    return dict[lang] && dict[lang][key] != null ? dict[lang][key] : en[key];
  }

  function apply(lang) {
    document.documentElement.lang = lang;
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var v = t(lang, el.getAttribute('data-i18n'));
      if (v != null) el.innerHTML = v;
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(function (el) {
      el.getAttribute('data-i18n-attr').split(';').forEach(function (pair) {
        var p = pair.split(':'), v = t(lang, p[1]);
        if (v != null) el.setAttribute(p[0], v);
      });
    });
    var title = t(lang, 'meta.title');
    if (title) document.title = title;
    document.querySelectorAll('[data-lang]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-lang') === lang));
    });
    window.KALORAT_LANG = lang;
    document.dispatchEvent(new CustomEvent('kalorat:lang', { detail: lang }));
  }

  capture();
  apply(initial());
  document.addEventListener('click', function (e) {
    var b = e.target.closest('[data-lang]');
    if (!b) return;
    var l = b.getAttribute('data-lang');
    store(l);
    apply(l);
  });
  window.kaloratT = function (key) { return t(window.KALORAT_LANG || 'en', key); };
})();
