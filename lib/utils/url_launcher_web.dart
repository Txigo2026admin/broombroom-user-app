import 'dart:js_interop';

@JS('open')
external void _open(JSString url, JSString target);

bool openUrlInWeb(String url) {
  try {
    _open(url.toJS, '_blank'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
