import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'payment_pending_screen.dart';
import 'thank_you_screen.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String bookingId;
  final String? orderId;
  final String? initialPhone;

  const PaymentVerificationScreen({
    super.key,
    required this.bookingId,
    this.orderId,
    this.initialPhone,
  });

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  String _statusMessage = 'Confirming your payment with Cashfree...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  Future<void> _startVerification() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _statusMessage = 'Confirming your payment with Cashfree...';
    });

    try {
      // 1. Poll Cashfree payment status through backend (up to 5 attempts)
      final statusResult = await PaymentService.verifyPaymentWithPolling(
        bookingId: widget.bookingId,
        maxAttempts: 6,
        interval: const Duration(milliseconds: 1500),
      );

      // 2. Clean query params from browser URL once verified
      PaymentService.clearUrlQueryParams();

      if (!mounted) return;

      // 3. Resolve phone number
      String phone = widget.initialPhone ?? '';
      if (phone.isEmpty && statusResult.booking != null) {
        phone = statusResult.booking!.customerMobile;
      }
      if (phone.isEmpty) {
        final storedPhone = await AuthService.getUserPhone();
        phone = storedPhone ?? '';
      }

      if (statusResult.paymentStatus == 'SUCCESS') {
        // Payment succeeded -> Route directly to Thank You Screen!
        final booking = statusResult.booking ??
            Booking(
              bookingId: widget.bookingId,
              customerName: '',
              customerMobile: phone,
              serviceType: 'One Way',
              state: '',
              pickupAddress: 'Pickup Point',
              dropAddress: 'Drop Point',
              pickupDate: '',
              pickupTime: '',
              vehicleCategory: 'Sedan',
              seater: 4,
              fare: statusResult.fare > 0 ? statusResult.fare : statusResult.paidAmount,
              advance: statusResult.advance > 0 ? statusResult.advance : statusResult.paidAmount,
              dueFare: statusResult.dueFare,
            );

        final double finalPaid = statusResult.paidAmount > 0
            ? statusResult.paidAmount
            : (statusResult.advance > 0 ? statusResult.advance : booking.advance);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouScreen(
              booking: booking,
              paidAmount: finalPaid,
              paymentMethod: statusResult.paymentMethod ?? 'Cashfree',
              phoneNumber: phone,
            ),
          ),
        );
      } else {
        // Payment not completed or declined -> Route to Payment Pending Screen
        if (!mounted) return;
        if (statusResult.booking != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingScreen(
                booking: statusResult.booking!,
                phoneNumber: phone,
                payableAdvance: statusResult.advance > 0
                    ? statusResult.advance
                    : statusResult.booking!.advance,
              ),
            ),
          );
        } else {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Payment was not completed. You can retry from your bookings.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Error verifying payment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_hasError) ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kAmberSoft,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kAmberDeep.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: kAmberDeep,
                        strokeWidth: 3.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verifying Payment',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: kInkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kInputBorder),
                    ),
                    child: Text(
                      'Booking ID: ${widget.bookingId}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment Status',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Unable to confirm payment status.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: kInkSoft,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _startVerification,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: kButtonShadow(),
                      ),
                      child: Center(
                        child: Text(
                          'RETRY VERIFICATION',
                          style: GoogleFonts.outfit(
                            color: kInk,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            phoneNumber: widget.initialPhone ?? '',
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kInputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kInputBorder),
                      ),
                      child: Center(
                        child: Text(
                          'GO TO HOME',
                          style: GoogleFonts.outfit(
                            color: kInk,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

