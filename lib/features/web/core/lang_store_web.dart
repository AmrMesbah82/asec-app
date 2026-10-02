/// On the web: remember the visitor's language in localStorage, and keep the
/// page's <html lang dir> in step (screen readers, search engines, browser
/// translation prompts).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const String _key = 'asec_site_lang';

JSObject? _storage() {
  try {
    return globalContext.getProperty<JSObject?>('localStorage'.toJS);
  } catch (_) {
    return null; // private mode / blocked storage
  }
}

String? readSavedLang() {
  try {
    final String? v = _storage()?.callMethod<JSString?>('getItem'.toJS, _key.toJS)?.toDart;
    return (v == 'en' || v == 'ar') ? v : null;
  } catch (_) {
    return null;
  }
}

void saveLang(String code) {
  try {
    _storage()?.callMethod<JSAny?>('setItem'.toJS, _key.toJS, code.toJS);
  } catch (_) {}
}

void applyToDocument(String code) {
  try {
    final JSObject? doc = globalContext.getProperty<JSObject?>('document'.toJS);
    final JSObject? html = doc?.getProperty<JSObject?>('documentElement'.toJS);
    html?.callMethod<JSAny?>('setAttribute'.toJS, 'lang'.toJS, code.toJS);
    html?.callMethod<JSAny?>('setAttribute'.toJS, 'dir'.toJS, (code == 'ar' ? 'rtl' : 'ltr').toJS);
  } catch (_) {}
}
