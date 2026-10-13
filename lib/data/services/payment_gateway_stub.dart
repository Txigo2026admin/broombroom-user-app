Future<String> launchCashfree(String paymentSessionId, String env) async {
  // Stub for non-web platforms or test fallback
  return '{"error": "Cashfree Web SDK only available on Web"}';
}

void clearUrlQueryParams() {
  // No-op on non-web platforms
}
