import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/booking.dart';
import '../../data/services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../account/bookings_screen.dart';
import '../home/home_screen.dart';
import 'thank_you_screen.dart';

class PaymentPendingScreen extends StatefulWidget {
  final Booking booking;
  final String phoneNumber;
  final double payableAdvance;

  const PaymentPendingScreen({
    super.key,
    required this.booking,
    required this.phoneNumber,
    required this.payableAdvance,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  bool _isProcessing = false;

  Future<void> _handleRetryPayment() async {
    final bookingId = widget.booking.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid booking reference. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Create-order again
      final orderResult = await PaymentService.createPaymentOrder(bookingId);

      if (!orderResult.success || orderResult.paymentSessionId == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  orderResult.message ?? 'Failed to initiate Cashfree payment.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Open Cashfree PG Checkout
      await PaymentService.openCashfreeCheckout(
        paymentSessionId: orderResult.paymentSessionId!,
        env: orderResult.environment ?? 'sandbox',
      );

      // Step 3: Check Payment Status with polling after Cashfree closes
      final statusResult = await PaymentService.verifyPaymentWithPolling(
        bookingId: bookingId,
        maxAttempts: 5,
        interval: const Duration(milliseconds: 1500),
      );

      // Clear any query params that might have been attached
      PaymentService.clearUrlQueryParams();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (statusResult.paymentStatus == 'SUCCESS') {
        // SUCCESS -> Navigate to Thank You page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouScreen(
              booking: statusResult.booking ?? widget.booking,
              paidAmount: statusResult.paidAmount > 0
                  ? statusResult.paidAmount
                  : widget.payableAdvance,
              paymentMethod: statusResult.paymentMethod ?? 'Cashfree',
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        // Cancelled / Still Pending / Failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              statusResult.paymentStatus == 'FAILED'
                  ? 'Payment was declined. Please try again with a different method.'
                  : 'Payment not completed yet. You can tap Pay Now to retry.',
            ),
            backgroundColor: statusResult.paymentStatus == 'FAILED'
                ? Colors.red
                : const Color(0xFFE65100),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dueAmount = widget.booking.dueFare > 0
        ? widget.booking.dueFare
        : (widget.booking.fare - widget.payableAdvance)
            .clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: kBgMid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Pending Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Pending',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your booking is recorded, but the advance payment was not completed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: kInkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Booking ID Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: kAmberSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kInputBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.confirmation_number_rounded,
                        color: kAmberDeep, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Booking ID: ${widget.booking.bookingId ?? "BB_${widget.booking.id ?? ''}"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Due Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kInputBorder),
                  boxShadow: kCardShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Summary',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFFB74D)),
                          ),
                          child: Text(
                            'PENDING',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: kInputBorder.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    _buildRow(
                      'Total Fare',
                      '₹ ${widget.booking.fare.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Advance Payable Now',
                      '₹ ${widget.payableAdvance.toStringAsFixed(0)}',
                      isBold: true,
                      valueColor: const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Remaining Due at Trip',
                      '₹ ${dueAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trip Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kInputBorder),
                  boxShadow: kCardShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Details',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTripPoint(
                      Icons.trip_origin_rounded,
                      Colors.green,
                      'Pickup',
                      widget.booking.pickupAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTripPoint(
                      Icons.location_on_rounded,
                      Colors.redAccent,
                      'Drop',
                      widget.booking.dropAddress,
                    ),
                    const SizedBox(height: 14),
                    Divider(color: kInputBorder.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            Icons.calendar_month_rounded,
                            'Date & Time',
                            '${widget.booking.pickupDate}, ${widget.booking.pickupTime}',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.directions_car_rounded,
                            'Car Type',
                            widget.booking.vehicleCategory,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attention Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF57F17), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your cab allocation will be prioritized immediately once the advance payment is received.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF5D4037),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // PAY NOW Button (Primary)
              GestureDetector(
                onTap: _isProcessing ? null : _handleRetryPayment,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: kButtonShadow(),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: kInk,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded,
                                  color: kInk, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'PAY NOW (₹ ${widget.payableAdvance.toStringAsFixed(0)})',
                                style: GoogleFonts.outfit(
                                  color: kInk,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pay Later / Go to Home Button (Secondary)
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomeScreen(phoneNumber: widget.phoneNumber),
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
                      'I\'LL PAY LATER (GO TO HOME)',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // View Bookings
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingsScreen(),
                    ),
                  );
                },
                child: Text(
                  'View My Bookings',
                  style: GoogleFonts.outfit(
                    color: kAmberDeep,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, color: kInkSoft),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? kInk,
          ),
        ),
      ],
    );
  }

  Widget _buildTripPoint(
      IconData icon, Color color, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: kInkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kAmberDeep, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: kInkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
