import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String> launchCashfree(
  String orderId,
  String paymentSessionId,
  String env,
) async {
  if (orderId.isEmpty || paymentSessionId.isEmpty) {
    return jsonEncode({
      'status': 'ERROR',
      'error': 'Missing Cashfree order details',
    });
  }

  // iOS: Preserve existing URL-based checkout.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return launchCashfreeUrl(paymentSessionId, env);
  }

  // Android: Use native Cashfree SDK.
  if (defaultTargetPlatform != TargetPlatform.android) {
    return jsonEncode({
      'status': 'UNSUPPORTED_PLATFORM',
      'error': 'Unsupported platform',
    });
  }

  try {
    final completer = Completer<String>();

    final environment =
        env.toLowerCase() == 'production'
            ? CFEnvironment.PRODUCTION
            : CFEnvironment.SANDBOX;

    final session =
        CFSessionBuilder()
            .setEnvironment(environment)
            .setOrderId(orderId)
            .setPaymentSessionId(paymentSessionId)
            .build();

    final checkout = CFWebCheckoutPaymentBuilder().setSession(session!).build();

    final gateway = CFPaymentGatewayService();

    gateway.setCallback(
      (String returnedOrderId) {
        if (!completer.isCompleted) {
          completer.complete(
            jsonEncode({
              'status': 'CALLBACK_SUCCESS',
              'orderId': returnedOrderId,
            }),
          );
        }
      },
      (CFErrorResponse error, String returnedOrderId) {
        if (!completer.isCompleted) {
          completer.complete(
            jsonEncode({
              'status': 'CALLBACK_ERROR',
              'orderId': returnedOrderId,
              'error': error.getMessage(),
            }),
          );
        }
      },
    );

    gateway.doPayment(checkout);

    return await completer.future;
  } catch (e) {
    return jsonEncode({'status': 'ERROR', 'error': e.toString()});
  }
}

// Existing URL checkout for iOS.
Future<String> launchCashfreeUrl(String paymentSessionId, String env) async {
  final isProduction = env.toLowerCase() == 'production';

  final checkoutUrl =
      isProduction
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
        return jsonEncode({'status': 'OPENED', 'url': checkoutUrl});
      }
    }
  } catch (e) {
    return jsonEncode({'status': 'ERROR', 'error': e.toString()});
  }

  return jsonEncode({
    'status': 'ERROR',
    'error': 'Could not launch Cashfree checkout',
  });
}

void clearUrlQueryParams() {}
