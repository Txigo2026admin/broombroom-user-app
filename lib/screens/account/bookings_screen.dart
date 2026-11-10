import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/booking_service.dart';
import '../../data/models/booking.dart';
import '../../theme/app_theme.dart';
import '../booking/booking_support_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;
  List<Booking> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final bookings = await BookingService.getMyBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  List<Booking> get _filteredBookings {
    if (_selectedTab == 0) {
      return _allBookings
          .where((b) => b.status == 'Confirmed' || b.status == 'Pending')
          .toList();
    } else if (_selectedTab == 1) {
      return _allBookings.where((b) => b.status == 'Confirmed').toList();
    } else {
      return _allBookings
          .where((b) => b.status == 'Completed' || b.status == 'Cancelled')
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bookings',
          style: GoogleFonts.outfit(
            color: kInk,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Decorative Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/mandala_footer.png',
              fit: BoxFit.cover,
              color: kAmber.withValues(alpha: 0.06),
              colorBlendMode: BlendMode.dstIn,
            ),
          ),
          // Content
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Custom Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kInputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kInputBorder),
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, 'Upcoming'),
                        _buildTab(1, 'Current'),
                        _buildTab(2, 'History'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(color: kAmberDeep),
                          )
                          : _filteredBookings.isEmpty
                          ? _buildEmptyState()
                          : _buildBookingsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBookingCard(
            crn: booking.bookingId ?? 'TX000000',
            from: booking.pickupAddress,
            to: booking.dropAddress,
            date: booking.pickupDate,
            time: booking.pickupTime,
            status: booking.status ?? 'Pending',
            cabType: booking.vehicleCategory,
            price: '₹${booking.fare.toInt()}',
            driverName: booking.driverName,
            driverNumber: booking.driverNumber,
            carNo: booking.carNo,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/empty_bookings.png', height: 240),
          const SizedBox(height: 16),
          Text(
            "No active bookings found",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String crn,
    required String from,
    required String to,
    required String date,
    required String time,
    required String status,
    required String cabType,
    required String price,
    String? driverName,
    String? driverNumber,
    String? carNo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kInputBorder),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        children: [
          // CRN and Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kInputBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(color: kInputBorder.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  crn,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: kAmberDeep,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kAmberSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kInputBorder),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Route Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 10, color: kAmber),
                        Container(height: 32, width: 2, color: kInputBorder),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: kAmberDeep,
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            from,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            to,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.outfit(
                            color: kInkSoft,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: kInk,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: kInputBorder.withValues(alpha: 0.6)),
                ),
                // Cab and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled_rounded,
                          color: kAmberDeep,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cabType,
                          style: GoogleFonts.outfit(
                            color: kInk,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kAmberDeep,
                      ),
                    ),
                  ],
                ),
                if (driverName != null && driverName.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: kInputBorder.withValues(alpha: 0.6)),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kAmberSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kInputBorder),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: kAmberDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: kInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${driverNumber ?? ''} • ${carNo ?? ''}',
                              style: GoogleFonts.outfit(
                                color: kInkSoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: kAmberSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kInputBorder),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Text(
                                'View Details',
                                style: GoogleFonts.outfit(
                                  color: kInk,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingSupportScreen(
                                bookingId: crn,
                                pickupAddress: from,
                                dropAddress: to,
                                date: date,
                                time: time,
                                status: status,
                                vehicleCategory: cabType,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: kPrimaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kAmber.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Support',
                              style: GoogleFonts.outfit(
                                color: kInk,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(colors: [Color(0xFFFFD54F), kAmber])
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? kInk : kInkSoft,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
