import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/booking_service.dart';
import '../../data/models/booking.dart';

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
      return _allBookings.where((b) => b.status == 'Confirmed' || b.status == 'Pending').toList();
    } else if (_selectedTab == 1) {
      return _allBookings.where((b) => b.status == 'Confirmed').toList(); // Simplified for demo
    } else {
      return _allBookings.where((b) => b.status == 'Completed' || b.status == 'Cancelled').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bookings',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
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
              color: Colors.grey.withOpacity(0.05),
              colorBlendMode: BlendMode.dstIn,
            ),
          ),
          // Content
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Custom Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
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
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
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
          Image.asset(
            'assets/images/empty_bookings.png',
            height: 280,
          ),
          const SizedBox(height: 20),
          Text(
            "No active bookings found",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // CRN and Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  crn,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.outfit(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
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
                        const Icon(Icons.circle, size: 10, color: Colors.amber),
                        Container(height: 30, width: 2, color: Colors.grey.shade300),
                        const Icon(Icons.location_on, size: 14, color: Colors.orange),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(from, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          Text(to, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(date, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(time, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                // Cab and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car_filled_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(cabType, style: GoogleFonts.outfit(color: Colors.black87)),
                      ],
                    ),
                    Text(
                      price,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
                if (driverName != null && driverName.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: Colors.amber.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('${driverNumber ?? ''} • ${carNo ?? ''}', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.amber.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.outfit(color: Colors.amber.shade400, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade400,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Support',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
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
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber.shade400 : Colors.white,
            borderRadius: BorderRadius.circular(isSelected ? 6 : 0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
