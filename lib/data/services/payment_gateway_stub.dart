import 'package:url_launcher/url_launcher.dart';

Future<String> launchCashfree(String paymentSessionId, String env) async {
  final isProduction = env.toLowerCase() == 'production';
  final checkoutUrl = isProduction
      ? 'https://payments.cashfree.com/order/#$paymentSessionId'
      : 'https://sandbox.cashfree.com/pg/orders/sessions/$paymentSessionId';

  final uri = Uri.parse(checkoutUrl);
  try {
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return '{"status": "OPENED", "url": "$checkoutUrl"}';
      }
    }
  } catch (e) {
    return '{"error": "$e"}';
  }
  return '{"error": "Could not launch Cashfree checkout"}';
}

void clearUrlQueryParams() {
  // No-op on non-web platforms
}
