import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/booking.dart';
import '../../theme/app_theme.dart';
import 'thank_you_screen.dart';
import 'payment_pending_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String time;
  final bool isOneWay;
  final String carName;
  final String price;
  final String phoneNumber;
  final String? petType;
  final bool isRental;
  final String? rentalPackage;
  final bool isAirport;
  final String? airportDirection;
  final String? airportTerminal;

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
    this.petType,
    this.isRental = false,
    this.rentalPackage,
    this.isAirport = false,
    this.airportDirection,
    this.airportTerminal,
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _pickupLocationController;
  late TextEditingController _dropLocationController;
  late TextEditingController _phoneController;

  // Add-on States
  bool _includeExpressway = false;
  bool _includeLanguage = false;
  bool _includeLuggage = false;
  bool _includeNewCar = false;
  bool _includePet = false;
  int _petCount = 1;

  // Add-on Prices
  static const double priceExpressway = 293.0;
  static const double priceLanguage = 199.0;
  static const double priceLuggage = 149.0;
  static const double priceNewCar = 249.0;
  static const double pricePerPet = 1000.0;

  // Coupon & Price State
  late double _basePrice;
  double _discount = 0;
  String _appliedCoupon = '';
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    String displayPhone = widget.phoneNumber;
    if (displayPhone.startsWith('+91')) {
      displayPhone = displayPhone.substring(3);
    } else if (displayPhone.startsWith('91') && displayPhone.length > 10) {
      displayPhone = displayPhone.substring(2);
    }
    _phoneController = TextEditingController(text: displayPhone);
    // Auto-populate pickup and drop locations from the booking search
    _pickupLocationController = TextEditingController(text: widget.from);
    _dropLocationController = TextEditingController(text: widget.to);
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    final rawPrice =
        double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (widget.petType != null) {
      _includePet = true;
      _petCount = 1;
      _basePrice = (rawPrice - pricePerPet).clamp(0.0, double.infinity);
    } else {
      _includePet = false;
      _petCount = 1;
      _basePrice = rawPrice;
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    final savedPhone = await AuthService.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null &&
            name.isNotEmpty &&
            name != 'New User' &&
            _nameController.text.isEmpty) {
          _nameController.text = name;
        }
        if (_phoneController.text.isEmpty && savedPhone != null) {
          String p = savedPhone;
          if (p.startsWith('+91')) {
            p = p.substring(3);
          } else if (p.startsWith('91') && p.length > 10) {
            p = p.substring(2);
          }
          _phoneController.text = p;
        }
      });
    }
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
          const SnackBar(
            content: Text('Invalid Coupon Code'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon $code Applied Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  double get _addonsTotal {
    double total = 0;
    if (_includeExpressway) total += priceExpressway;
    if (_includeLanguage) total += priceLanguage;
    if (_includeLuggage) total += priceLuggage;
    if (_includeNewCar) total += priceNewCar;
    if (_includePet) total += (_petCount * pricePerPet);
    return total;
  }

  double get _finalPrice => (_basePrice + _addonsTotal) - _discount;

  int _selectedPaymentPercent = 25;
  double get _payableAmount => _selectedPaymentPercent == 0
      ? 0.0
      : (_finalPrice * (_selectedPaymentPercent / 100.0));

  bool _isCreatingBooking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pickupLocationController.dispose();
    _dropLocationController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmBooking() async {
    final String pickup = _pickupLocationController.text.trim().isNotEmpty
        ? _pickupLocationController.text.trim()
        : widget.from;
    final String drop = _dropLocationController.text.trim().isNotEmpty
        ? _dropLocationController.text.trim()
        : widget.to;
    final String name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Customer';
    final String phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : widget.phoneNumber;

    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify pickup and drop locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Auto-save user name for future bookings
    if (_nameController.text.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());
    }

    setState(() {
      _isCreatingBooking = true;
    });

    final double advanceAmount = _payableAmount;
    final double dueAmount = (_finalPrice - advanceAmount).clamp(0, double.infinity);

    final String chosenCarCategory = _includePet
        ? (widget.carName.contains('Pet')
            ? '${widget.carName} (Pet count: $_petCount)'
            : '${widget.carName} (with $_petCount pet${_petCount > 1 ? "s" : ""})')
        : widget.carName;

    final booking = Booking(
      customerName: name,
      customerMobile: phone,
      customerEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      serviceType: widget.isAirport
          ? 'Airport'
          : (widget.isRental
              ? 'Rental'
              : (widget.isOneWay ? 'Outstation oneway' : 'Outstation roundtrip')),
      airportDirection: widget.airportDirection,
      airportTerminal: widget.airportTerminal,
      rentalPackage: widget.rentalPackage,
      state: 'Default',
      pickupAddress: pickup,
      dropAddress: drop,
      pickupDate: widget.date,
      pickupTime: widget.time,
      vehicleCategory: chosenCarCategory,
      seater: 4,
      fare: _finalPrice,
      advance: advanceAmount,
      dueFare: dueAmount,
    );

    try {
      // 1. POST /api/bookings -> Booking created
      final createdBooking = await BookingService.createBooking(booking);

      if (!mounted) return;

      if (createdBooking == null) {
        setState(() {
          _isCreatingBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create booking. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If "Book at ₹0" was chosen:
      if (advanceAmount <= 0) {
        setState(() {
          _isCreatingBooking = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouScreen(
              booking: createdBooking,
              paidAmount: 0,
              paymentMethod: 'Pay on Trip',
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
        return;
      }

      // 2. POST /api/payment/create-order -> Cashfree paymentSessionId
      final orderRes = await PaymentService.createPaymentOrder(
          createdBooking.bookingId ?? '');

      if (!mounted) return;

      if (!orderRes.success || orderRes.paymentSessionId == null) {
        setState(() {
          _isCreatingBooking = false;
        });
        // Failed to create payment order -> route to Payment Pending Screen so user can click PAY NOW
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingScreen(
              booking: createdBooking,
              phoneNumber: widget.phoneNumber,
              payableAdvance: advanceAmount,
            ),
          ),
        );
        return;
      }

      // 3. OPEN CASHFREE
      await PaymentService.openCashfreeCheckout(
        paymentSessionId: orderRes.paymentSessionId!,
        env: orderRes.environment ?? 'sandbox',
      );

      // 4. Poll payment status from backend after Cashfree closes
      final statusRes = await PaymentService.verifyPaymentWithPolling(
        bookingId: createdBooking.bookingId ?? '',
        maxAttempts: 5,
        interval: const Duration(milliseconds: 1500),
      );

      // Clear any query params that might have been attached
      PaymentService.clearUrlQueryParams();

      if (!mounted) return;

      setState(() {
        _isCreatingBooking = false;
      });

      if (statusRes.paymentStatus == 'SUCCESS') {
        // SUCCESS -> Thank You Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouScreen(
              booking: statusRes.booking ?? createdBooking,
              paidAmount: statusRes.paidAmount > 0
                  ? statusRes.paidAmount
                  : advanceAmount,
              paymentMethod: statusRes.paymentMethod ?? 'Cashfree',
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        // Cancel/Close or Pending -> Payment Pending Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingScreen(
              booking: statusRes.booking ?? createdBooking,
              phoneNumber: widget.phoneNumber,
              payableAdvance: advanceAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Review Your Booking',
          style: GoogleFonts.outfit(
            color: kInk,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAmberSoft,
                border: Border.all(color: kInputBorder),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: kAmberDeep,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 8),
                  _buildCancellationPolicy(),
                  const SizedBox(height: 10),
                  _buildContactForm(),
                  const SizedBox(height: 10),
                  _buildCouponsSection(),
                  const SizedBox(height: 10),
                  _buildPersonalizeSection(),
                  const SizedBox(height: 10),
                  _buildInclusionsExclusionsSection(),
                  const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kAmberSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kInputBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_rounded, size: 13, color: kAmberDeep),
                const SizedBox(width: 5),
                Text(
                  'TRIP SUMMARY',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: kAmberDeep,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAirport
                ? '${widget.from} -> ${widget.to}'
                : (widget.isRental
                    ? '${widget.from} (${widget.rentalPackage ?? "Rental"})'
                    : '${widget.from} -> ${widget.to} (${widget.isOneWay ? "Oneway" : "Roundtrip"})'),
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
          const SizedBox(height: 6),
          _buildSummaryItem('Car Type:', '${widget.carName} or Equivalent'),
          _buildSummaryItem('Pickup Date:', '${widget.date} ${widget.time}'),
          if (widget.airportTerminal != null && widget.airportTerminal!.isNotEmpty)
            _buildSummaryItem('Terminal:', widget.airportTerminal!),
          _buildSummaryItem(
            'Kms included:',
            widget.isRental && widget.rentalPackage != null
                ? widget.rentalPackage!
                : '260 kms',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.outfit(color: kInkSoft, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: kInk,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kAmberSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInputBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_filled_rounded,
            color: kAmberDeep,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Free cancellation till 1 hr of departure',
              style: GoogleFonts.outfit(
                color: kInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: kAmberSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kInputBorder),
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: kAmberDeep,
                  size: 15,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Contact & Pickup Details',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: kInputBorder.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kInputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kInputBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+91',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: kInkSoft,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kInputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kInputBorder),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Mobile No.',
                      hintStyle: GoogleFonts.outfit(
                        color: kInkSoft.withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField('Email ID', _emailController),
          const SizedBox(height: 8),
          _buildTextField('Pickup Location', _pickupLocationController),
          const SizedBox(height: 8),
          _buildTextField('Drop Location', _dropLocationController),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFormButton(Icons.add_rounded, 'Alternate Email'),
              const SizedBox(width: 8),
              _buildFormButton(Icons.add_rounded, 'Add GST'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInputBorder),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(color: kInk, fontWeight: FontWeight.w500, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: kInkSoft.withValues(alpha: 0.6), fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _buildFormButton(IconData icon, String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: kAmberSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kInputBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: kAmberDeep),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kAmberSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kInputBorder),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: kAmberDeep,
                size: 14,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Coupons & Offers',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: kInputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _appliedCoupon.isNotEmpty ? Colors.green : kInputBorder,
                  ),
                ),
                child: TextField(
                  controller: _couponController,
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ENTER COUPON (Try BROOMBOOM10)',
                    hintStyle: GoogleFonts.outfit(
                      color: kInkSoft.withValues(alpha: 0.6),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _applyCoupon,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'APPLY',
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_appliedCoupon.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4),
            child: Text(
              'Applied: $_appliedCoupon (-₹${_discount.toStringAsFixed(0)})',
              style: GoogleFonts.outfit(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalizeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: kAmberDeep, size: 18),
              const SizedBox(width: 7),
              Text(
                'Personalize Your Journey',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Enhance your travel experience with our premium add-ons',
            style: GoogleFonts.outfit(fontSize: 11, color: kInkSoft),
          ),
          const SizedBox(height: 8),
          Divider(color: kInputBorder.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
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
            'Extra Luggage Carrier',
            '₹ 149',
            isSelected: _includeLuggage,
            onChanged: (val) => setState(() => _includeLuggage = val!),
          ),
          _buildAddonItem(
            'Guaranteed New Model Vehicle',
            '₹ 249',
            isSelected: _includeNewCar,
            onChanged: (val) => setState(() => _includeNewCar = val!),
          ),
          _buildPetAddonItem(),
        ],
      ),
    );
  }

  Widget _buildPetAddonItem() {
    final String title = widget.petType != null && widget.petType!.isNotEmpty
        ? 'Carrying Pet (${widget.petType})'
        : 'Carrying Pet';
    final int totalPetPrice = (_petCount * pricePerPet).toInt();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _includePet ? kAmberSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: _includePet ? Border.all(color: kInputBorder) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _includePet,
              onChanged: (val) {
                setState(() {
                  _includePet = val ?? false;
                  if (_includePet && _petCount < 1) _petCount = 1;
                });
              },
              activeColor: kAmberDeep,
              checkColor: Colors.white,
              side: const BorderSide(color: kInputBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pets_rounded, size: 14, color: kAmberDeep),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.petType != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: kAmberDeep,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PET CAB',
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _includePet
                      ? '₹ $totalPetPrice (₹ 1,000/pet)'
                      : '₹ 1,000 per pet',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: kAmberDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_includePet)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kInputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      if (_petCount > 1) {
                        setState(() => _petCount--);
                      } else {
                        setState(() => _includePet = false);
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Icon(Icons.remove, size: 13, color: kInk),
                    ),
                  ),
                  Text(
                    '$_petCount',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: kInk,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_petCount < 5) {
                        setState(() => _petCount++);
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Icon(Icons.add, size: 13, color: kInk),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddonItem(
    String title,
    String price, {
    required bool isSelected,
    bool isPopular = false,
    required ValueChanged<bool?> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? kAmberSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: kInputBorder) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: kAmberDeep,
              checkColor: Colors.white,
              side: const BorderSide(color: kInputBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: kAmberDeep,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'POPULAR',
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  price,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: kAmberDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsExclusionsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 5),
                Text(
                  'INCLUSIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildInclusionPoint(
            Icons.check_circle_rounded,
            'Base Fare & Fuel Charges',
            true,
          ),
          _buildInclusionPoint(
            Icons.check_circle_rounded,
            'Driver Allowance',
            true,
          ),
          const SizedBox(height: 8),
          Divider(color: kInputBorder.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  size: 13,
                  color: Color(0xFFC62828),
                ),
                const SizedBox(width: 5),
                Text(
                  'EXCLUSIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFC62828),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildInclusionPoint(Icons.cancel_rounded, 'Toll / State Tax', false),
          _buildInclusionPoint(Icons.cancel_rounded, 'GST (5%)', false),
          _buildInclusionPoint(Icons.cancel_rounded, 'Parking Charges', false),
          const SizedBox(height: 6),
          Divider(color: kInputBorder.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(
            'Terms and Conditions',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Night allowance is applicable from 10 PM to 6 AM.\n• Extra kms will be charged at ₹14.5/km.\n• Toll and state tax will be extra as per actuals.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: kInkSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionPoint(IconData icon, String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isIncluded ? Colors.green : Colors.red.shade400,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 12, color: kInk),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(
          top: BorderSide(color: kInputBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total Fare ',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: kInkSoft,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_discount > 0)
                    Text(
                      '₹ ${_basePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: kInkSoft.withValues(alpha: 0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '₹ ${_finalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kAmberDeep,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPayOption('Book at ₹0', percent: 0),
              const SizedBox(width: 4),
              _buildPayOption('Pay 25%', percent: 25),
              const SizedBox(width: 4),
              _buildPayOption('Pay 100%', percent: 100),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _isCreatingBooking ? null : _handleConfirmBooking,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: kButtonShadow(),
                    ),
                    child:
                        _isCreatingBooking
                            ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: kInk,
                                  strokeWidth: 2.2,
                                ),
                              ),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedPaymentPercent == 0
                                      ? 'Book Now'
                                      : 'Pay Now',
                                  style: GoogleFonts.outfit(
                                    color: kInk,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  _selectedPaymentPercent == 0
                                      ? 'Pay Later'
                                      : '₹ ${_payableAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    color: kInk,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

  Widget _buildPayOption(String label, {required int percent}) {
    final bool isSelected = _selectedPaymentPercent == percent;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentPercent = percent;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(colors: [Color(0xFFFFD54F), kAmber])
                  : null,
          color: isSelected ? null : kInputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kAmberDeep : kInputBorder),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? kInk : kInkSoft,
          ),
        ),
      ),
    );
  }
}
