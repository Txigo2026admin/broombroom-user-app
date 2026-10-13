import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/booking.dart';
import '../../theme/app_theme.dart';
import '../account/bookings_screen.dart';
import '../home/home_screen.dart';

class ThankYouScreen extends StatelessWidget {
  final Booking booking;
  final double paidAmount;
  final String? paymentMethod;
  final String phoneNumber;

  const ThankYouScreen({
    super.key,
    required this.booking,
    required this.paidAmount,
    this.paymentMethod,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final double dueAmount =
        booking.dueFare > 0
            ? booking.dueFare
            : (booking.fare - paidAmount).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: kBgMid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Success Badge Animation / Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Thank You!',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your booking has been successfully confirmed.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      'Booking ID: ${booking.bookingId ?? "BB_${booking.id ?? ''}"}',
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

              // Payment Status Card
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
                          'Payment Details',
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
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF81C784)),
                          ),
                          child: Text(
                            'PAID',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: kInputBorder.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    _buildRow(
                      'Advance Paid',
                      '₹ ${paidAmount.toStringAsFixed(0)}',
                      isBold: true,
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 8),
                    if (paymentMethod != null && paymentMethod!.isNotEmpty) ...[
                      _buildRow('Payment Mode', paymentMethod!),
                      const SizedBox(height: 8),
                    ],
                    _buildRow(
                      'Remaining Due at Trip',
                      '₹ ${dueAmount.toStringAsFixed(0)}',
                      isBold: true,
                      valueColor: kInk,
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
                      'Trip Summary',
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
                      booking.pickupAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTripPoint(
                      Icons.location_on_rounded,
                      Colors.redAccent,
                      'Drop',
                      booking.dropAddress,
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
                            '${booking.pickupDate}, ${booking.pickupTime}',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.directions_car_rounded,
                            'Car Type',
                            booking.vehicleCategory,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver Notice Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kAmberSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInputBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: kAmberDeep, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Driver details and vehicle number will be sent via SMS / WhatsApp prior to departure.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: kInk,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomeScreen(phoneNumber: phoneNumber),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: kButtonShadow(),
                  ),
                  child: Center(
                    child: Text(
                      'BACK TO HOME',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingsScreen(),
                    ),
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
                      'VIEW MY BOOKINGS',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
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
