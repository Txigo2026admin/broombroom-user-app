import 'dart:convert';

Future<String> launchCashfree(
  String orderId,
  String paymentSessionId,
  String env,
) async {
  return jsonEncode({
    'status': 'UNSUPPORTED_PLATFORM',
    'error': 'Cashfree checkout is not supported on this platform.',
  });
}

void clearUrlQueryParams() {}
