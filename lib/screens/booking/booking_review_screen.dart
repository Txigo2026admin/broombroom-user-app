import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/booking_service.dart';
import '../../data/models/booking.dart';
import '../home/home_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String time;
  final bool isOneWay;
  final String carName;
  final String price;
  final String phoneNumber;

  const BookingReviewScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.isOneWay,
    required this.carName,
    required this.price,
    required this.phoneNumber,
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _dropLocationController = TextEditingController();
  late TextEditingController _phoneController;

  // Add-on States
  bool _includeExpressway = false;
  bool _includeLanguage = false;
  bool _includeLuggage = false;
  bool _includeNewCar = false;

  // Add-on Prices
  static const double priceExpressway = 293.0;
  static const double priceLanguage = 199.0;
  static const double priceLuggage = 149.0;
  static const double priceNewCar = 249.0;

  // Coupon & Price State
  late double _basePrice;
  double _discount = 0;
  String _appliedCoupon = '';
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    String displayPhone = widget.phoneNumber;
    if (displayPhone.startsWith('91') && displayPhone.length > 10) {
      displayPhone = displayPhone.substring(2);
    }
    _phoneController = TextEditingController(text: displayPhone);

    // Initialize price (parsing '₹ 3243' -> 3243.0)
    _basePrice = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  void _applyCoupon() {
    String code = _couponController.text.toUpperCase().trim();
    setState(() {
      if (code == 'BROOMBOOM10') {
        _discount = _basePrice * 0.10;
        _appliedCoupon = code;
      } else if (code == 'FIRST500') {
        _discount = 500.0;
        _appliedCoupon = code;
      } else {
        _discount = 0;
        _appliedCoupon = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Coupon Code'), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon $code Applied Successfully!'), backgroundColor: Colors.green),
      );
    });
  }

  double get _addonsTotal {
    double total = 0;
    if (_includeExpressway) total += priceExpressway;
    if (_includeLanguage) total += priceLanguage;
    if (_includeLuggage) total += priceLuggage;
    if (_includeNewCar) total += priceNewCar;
    return total;
  }

  double get _finalPrice => (_basePrice + _addonsTotal) - _discount;

  bool _isCreatingBooking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pickupLocationController.dispose();
    _dropLocationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmBooking() async {
    if (_nameController.text.isEmpty || _pickupLocationController.text.isEmpty || _dropLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isCreatingBooking = true;
    });

    final booking = Booking(
      customerName: _nameController.text,
      customerMobile: widget.phoneNumber,
      customerEmail: _emailController.text,
      serviceType: widget.isOneWay ? 'Outstation oneway' : 'Outstation roundtrip',
      state: 'Default', // Ideally should be fetched or passed
      pickupAddress: _pickupLocationController.text,
      dropAddress: _dropLocationController.text,
      pickupDate: widget.date,
      pickupTime: widget.time,
      vehicleCategory: widget.carName,
      seater: 4, // Default or parse from carName
      fare: _finalPrice,
      advance: _finalPrice * 0.25,
      dueFare: _finalPrice * 0.75,
    );

    final result = await BookingService.createBooking(booking);

    if (mounted) {
      setState(() {
        _isCreatingBooking = false;
      });

      if (result != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Booking Confirmed!'),
            content: Text('Your booking ID is ${result.bookingId}. We have received your request.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen(phoneNumber: widget.phoneNumber)),
                    (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm booking. Please try again.')),
        );
      }
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
          'Review Your Booking',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.amber.shade400, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildCancellationPolicy(),
                  const SizedBox(height: 20),
                  _buildContactForm(),
                  const SizedBox(height: 24),
                  _buildCouponsSection(),
                  const SizedBox(height: 24),
                  _buildPersonalizeSection(),
                  const SizedBox(height: 24),
                  _buildInclusionsExclusionsSection(),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
          _buildBottomPaymentBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.from} -> ${widget.to} (${widget.isOneWay ? "Oneway" : "Roundtrip"})',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSummaryItem('Car Type:', '${widget.carName} or Equivalent'),
          _buildSummaryItem('Pickup Date:', '${widget.date} ${widget.time}'),
          _buildSummaryItem('Kms included:', '260 kms'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Text('$label ', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Free cancellation till 1 hr of departure',
              style: GoogleFonts.outfit(color: Colors.brown.shade700, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Pickup Details',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Text('+91', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Mobile No.',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    Positioned(
                      top: -2,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        color: Colors.grey.shade100,
                        child: Text('Mobile No.', style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Email ID', _emailController),
          const SizedBox(height: 16),
          _buildTextField('Pickup Location', _pickupLocationController),
          const SizedBox(height: 16),
          _buildTextField('Drop Location', _dropLocationController),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFormButton(Icons.add, 'Alternate Email'),
              const SizedBox(width: 12),
              _buildFormButton(Icons.add, 'Add GST'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFormButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16, color: Colors.amber.shade400),
        label: Text(label, style: GoogleFonts.outfit(color: Colors.amber.shade400, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.amber.shade300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coupons & Offers', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _appliedCoupon.isNotEmpty ? Colors.green.shade300 : Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ENTER A COUPON (Try BROOMBOOM10)',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('APPLY', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (_appliedCoupon.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Text(
              'Applied: $_appliedCoupon (-₹${_discount.toStringAsFixed(0)})',
              style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalizeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.amber.shade400, size: 20),
              const SizedBox(width: 8),
              Text('Personalize Your Journey', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Enhance your travel experience with our premium add-ons', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade700)),
          const Divider(height: 32),
          _buildAddonItem(
            '${widget.from} - ${widget.to} Expressway',
            '₹ 293',
            isSelected: _includeExpressway,
            isPopular: true,
            onChanged: (val) => setState(() => _includeExpressway = val!),
          ),
          _buildAddonItem(
            'Chauffeurs who know your language',
            '₹ 199',
            isSelected: _includeLanguage,
            onChanged: (val) => setState(() => _includeLanguage = val!),
          ),
          _buildAddonItem(
            'Cab with Luggage Carrier',
            '₹ 149',
            isSelected: _includeLuggage,
            description: 'Get a car with a luggage carrier that will make your roadtrip extra comfortable. Our chauffeurs will make sure that your luggage is loaded, securely fastened and unloaded based on your convenience',
            onChanged: (val) => setState(() => _includeLuggage = val!),
          ),
          _buildAddonItem(
            'New Car Promise - Model that is 2023 or newer',
            '₹ 249',
            isSelected: _includeNewCar,
            onChanged: (val) => setState(() => _includeNewCar = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonItem(String title, String price, {bool isPopular = false, bool isSelected = false, String? description, ValueChanged<bool?>? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.amber.shade100 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onChanged ?? (val) {},
                activeColor: Colors.amber.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (isPopular) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text('Most Popular', style: GoogleFonts.outfit(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              Text(price, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          if (description != null && isSelected) ...[
            const Padding(
              padding: EdgeInsets.only(left: 48, top: 8),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Text(description, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInclusionsExclusionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inclusions/Exclusions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INCLUSIONS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              _buildInclusionPoint(Icons.check_circle, 'Fuel Charges', true),
              _buildInclusionPoint(Icons.check_circle, 'Driver Allowance', true),
              if (!widget.isOneWay) ...[
                _buildInclusionPoint(Icons.check_circle, 'Driver Driving Allowance', true),
                _buildInclusionPoint(Icons.check_circle, 'Hour Charges', true),
              ],
              const Divider(height: 24),
              Text('EXCLUSIONS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              _buildInclusionPoint(Icons.cancel, 'Toll / State Tax', false),
              _buildInclusionPoint(Icons.cancel, 'GST (5%)', false),
              _buildInclusionPoint(Icons.cancel, 'Parking Charges', false),
              const Divider(height: 32),
              Text(
                'Terms and Conditions',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '• Night allowance is applicable from 10 PM to 6 AM.\n• Extra kms will be charged at ₹14.5/km.\n• Toll and state tax will be extra as per actuals.',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInclusionPoint(IconData icon, String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isIncluded ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Total Fare ', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_discount > 0)
                    Text(
                      '₹ ${_basePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough),
                    ),
                  Text('₹ ${_finalPrice.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPayOption('Book at ₹0'),
              const SizedBox(width: 8),
              _buildPayOption('Pay 25%', isSelected: true),
              const SizedBox(width: 8),
              _buildPayOption('Pay 100%'),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isCreatingBooking ? null : _handleConfirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isCreatingBooking
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Pay Now',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('₹ ${(_finalPrice * 0.25).toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayOption(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber.shade400 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.amber.shade400 : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
