import 'dart:js_interop';

@JS('cashfreeCheckout')
external JSPromise<JSString> _cashfreeCheckout(JSString paymentSessionId, JSString env);

@JS('clearUrlQueryParams')
external void _clearUrlQueryParams();

Future<String> launchCashfree(String paymentSessionId, String env) async {
  try {
    final promise = _cashfreeCheckout(paymentSessionId.toJS, env.toJS);
    final jsResult = await promise.toDart;
    return jsResult.toDart;
  } catch (e) {
    return '{"error": "$e"}';
  }
}

void clearUrlQueryParams() {
  try {
    _clearUrlQueryParams();
  } catch (_) {}
}
