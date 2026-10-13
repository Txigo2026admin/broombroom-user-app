import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import 'api_service.dart';
import 'payment_gateway_helper.dart' as pg_helper;

class PaymentOrderResult {
  final bool success;
  final String? bookingId;
  final String? orderId;
  final String? paymentSessionId;
  final double amount;
  final String? paymentStatus;
  final String? message;
  final String? environment;

  PaymentOrderResult({
    required this.success,
    this.bookingId,
    this.orderId,
    this.paymentSessionId,
    this.amount = 0.0,
    this.paymentStatus,
    this.message,
    this.environment,
  });

  factory PaymentOrderResult.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResult(
      success: json['success'] == true,
      bookingId: json['bookingId'],
      orderId: json['orderId'],
      paymentSessionId: json['paymentSessionId'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'],
      message: json['message'],
      environment: json['environment'],
    );
  }
}

class PaymentStatusResult {
  final bool success;
  final String? bookingId;
  final String paymentStatus; // SUCCESS, PENDING, FAILED
  final double paidAmount;
  final String? paymentMethod;
  final double fare;
  final double advance;
  final double dueFare;
  final String? message;
  final Booking? booking;

  PaymentStatusResult({
    required this.success,
    this.bookingId,
    required this.paymentStatus,
    this.paidAmount = 0.0,
    this.paymentMethod,
    this.fare = 0.0,
    this.advance = 0.0,
    this.dueFare = 0.0,
    this.message,
    this.booking,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      success: json['success'] == true,
      bookingId: json['bookingId'],
      paymentStatus: (json['paymentStatus'] ?? 'PENDING').toString().toUpperCase(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      fare: (json['fare'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      dueFare: (json['dueFare'] ?? 0).toDouble(),
      message: json['message'],
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
    );
  }
}

class PaymentService {
  /// Calls POST /api/payment/create-order
  static Future<PaymentOrderResult> createPaymentOrder(
    String bookingId, {
    String? returnUrl,
  }) async {
    try {
      final effectiveReturnUrl =
          returnUrl ?? (kIsWeb ? Uri.base.origin : null);

      final response = await ApiService.post('/payment/create-order', {
        'bookingId': bookingId,
        if (effectiveReturnUrl != null && effectiveReturnUrl.isNotEmpty)
          'returnUrl': effectiveReturnUrl,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentOrderResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return PaymentOrderResult(
          success: false,
          message: data['message'] ?? 'Failed to create payment order',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in createPaymentOrder: $e');
      }
      return PaymentOrderResult(
        success: false,
        message: 'Connection error: $e',
      );
    }
  }

  /// Calls GET /api/payment/status/:bookingId
  static Future<PaymentStatusResult> checkPaymentStatus(String bookingId) async {
    try {
      final response = await ApiService.get('/payment/status/$bookingId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatusResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return PaymentStatusResult(
          success: false,
          paymentStatus: 'PENDING',
          message: data['message'] ?? 'Failed to check status',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkPaymentStatus: $e');
      }
      return PaymentStatusResult(
        success: false,
        paymentStatus: 'PENDING',
        message: 'Connection error: $e',
      );
    }
  }

  /// Polls payment status with retries (e.g. 5 attempts with 1.5s interval)
  /// to allow Cashfree backend sync to complete cleanly
  static Future<PaymentStatusResult> verifyPaymentWithPolling({
    required String bookingId,
    int maxAttempts = 5,
    Duration interval = const Duration(milliseconds: 1500),
  }) async {
    PaymentStatusResult lastResult = PaymentStatusResult(
      success: false,
      paymentStatus: 'PENDING',
    );

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      lastResult = await checkPaymentStatus(bookingId);
      if (lastResult.paymentStatus == 'SUCCESS') {
        return lastResult;
      }
      if (lastResult.paymentStatus == 'FAILED') {
        return lastResult;
      }
      if (attempt < maxAttempts) {
        await Future.delayed(interval);
      }
    }

    return lastResult;
  }

  /// Opens Cashfree Checkout (modal on web, fallback if other platform)
  static Future<String> openCashfreeCheckout({
    required String paymentSessionId,
    String env = 'sandbox',
  }) async {
    try {
      return await pg_helper.launchCashfree(paymentSessionId, env);
    } catch (e) {
      if (kDebugMode) {
        print('Error launching Cashfree: $e');
      }
      return '{"error": "$e"}';
    }
  }

  /// Cleans the browser address bar query parameters after payment verification
  static void clearUrlQueryParams() {
    try {
      pg_helper.clearUrlQueryParams();
    } catch (_) {}
  }
}
