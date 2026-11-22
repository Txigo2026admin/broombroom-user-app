import 'package:flutter_test/flutter_test.dart';
import 'package:broomboom_user_app/data/services/payment_service.dart';

void main() {
  group('Payment Models & Results', () {
    test('PaymentOrderResult parses success and session properly', () {
      final json = {
        'success': true,
        'bookingId': 'BB-12345',
        'orderId': 'BB_BB-12345_1732320000',
        'paymentSessionId': 'session_abc123',
        'amount': 500.0,
        'paymentStatus': 'PENDING',
        'environment': 'sandbox',
      };

      final result = PaymentOrderResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.bookingId, equals('BB-12345'));
      expect(result.orderId, equals('BB_BB-12345_1732320000'));
      expect(result.paymentSessionId, equals('session_abc123'));
      expect(result.amount, equals(500.0));
      expect(result.environment, equals('sandbox'));
    });

    test('PaymentStatusResult parses SUCCESS status properly', () {
      final json = {
        'success': true,
        'bookingId': 'BB-12345',
        'paymentStatus': 'SUCCESS',
        'paidAmount': 500.0,
        'paymentMethod': 'UPI',
        'fare': 2000.0,
        'advance': 500.0,
        'dueFare': 1500.0,
      };

      final result = PaymentStatusResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.paymentStatus, equals('SUCCESS'));
      expect(result.paidAmount, equals(500.0));
      expect(result.paymentMethod, equals('UPI'));
      expect(result.dueFare, equals(1500.0));
    });

    test('PaymentStatusResult parses PENDING and FAILED properly', () {
      final jsonPending = {
        'success': true,
        'bookingId': 'BB-12345',
        'paymentStatus': 'PENDING',
        'paidAmount': 0.0,
      };
      final resultPending = PaymentStatusResult.fromJson(jsonPending);
      expect(resultPending.paymentStatus, equals('PENDING'));

      final jsonFailed = {
        'success': true,
        'bookingId': 'BB-12345',
        'paymentStatus': 'FAILED',
      };
      final resultFailed = PaymentStatusResult.fromJson(jsonFailed);
      expect(resultFailed.paymentStatus, equals('FAILED'));
    });
  });
}
