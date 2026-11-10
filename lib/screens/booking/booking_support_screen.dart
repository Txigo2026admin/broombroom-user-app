import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/booking.dart';
import '../../data/services/settings_service.dart';
import '../../theme/app_theme.dart';

class BookingSupportScreen extends StatefulWidget {
  final Booking? booking;
  final String? bookingId;
  final String? pickupAddress;
  final String? dropAddress;
  final String? date;
  final String? time;
  final String? status;
  final String? vehicleCategory;

  const BookingSupportScreen({
    super.key,
    this.booking,
    this.bookingId,
    this.pickupAddress,
    this.dropAddress,
    this.date,
    this.time,
    this.status,
    this.vehicleCategory,
  });

  @override
  State<BookingSupportScreen> createState() => _BookingSupportScreenState();
}

class _BookingSupportScreenState extends State<BookingSupportScreen> {
  String _supportEmail = 'support@broomboomcabs.com';
  String _supportPhone = '+91 84484 45566';
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'All',
    'Driver & Cab',
    'Cancellations & Refunds',
    'Fares & Charges',
    'Safety & Policies',
  ];

  late final List<_FaqItem> _faqs = [
    _FaqItem(
      category: 'Driver & Cab',
      question: 'When will I receive my driver and cab details?',
      answer:
          'Driver and vehicle details (driver name, contact number, and cab registration number) are sent to you via SMS and WhatsApp 2 hours prior to your scheduled pickup time. They will also be visible directly in the "My Bookings" section of this app.',
    ),
    _FaqItem(
      category: 'Driver & Cab',
      question: 'What if my cab or driver is delayed?',
      answer:
          'BroomBoom Cabs operates on a strict punctuality standard. If your cab is delayed past the scheduled pickup time by more than 15 minutes, please tap our 24x7 Helpline below immediately. Our dispatch team will either coordinate with your driver or arrange a priority replacement cab at no extra charge.',
    ),
    _FaqItem(
      category: 'Driver & Cab',
      question: 'Can I change my pickup time or location?',
      answer:
          'Yes! You can reschedule your pickup time or alter the pickup point up to 4 hours before the journey. Please call or email our customer support with your Booking ID so our dispatch team can update your ride itinerary seamlessly.',
    ),
    _FaqItem(
      category: 'Cancellations & Refunds',
      question: 'What is the cancellation policy?',
      answer:
          'You enjoy Free Cancellation up to 6 hours before your scheduled departure. For cancellations within 6 hours of departure, a nominal cancellation fee (equivalent to the advance paid or base dispatch fee) may be deducted.',
    ),
    _FaqItem(
      category: 'Cancellations & Refunds',
      question: 'How long do refunds take to reflect in my account?',
      answer:
          'Eligible refunds are initiated immediately upon cancellation. Depending on your bank or payment method (UPI, credit/debit card, or net banking), funds typically reflect within 3 to 5 business days.',
    ),
    _FaqItem(
      category: 'Fares & Charges',
      question: 'Are toll taxes, parking, and state permit taxes included?',
      answer:
          'Our estimates cover driver allowances, fuel, and base distance. State road entry taxes, toll plazas (FASTag), and parking fees are either added as part of your transparent package estimate or paid as per actual receipts during the journey with no hidden markups.',
    ),
    _FaqItem(
      category: 'Fares & Charges',
      question: 'How are extra kilometers and extra hours billed?',
      answer:
          'If your trip exceeds the included kilometers or package duration, additional usage is billed transparently at the per-km and per-hour rates specified on your booking confirmation.',
    ),
    _FaqItem(
      category: 'Fares & Charges',
      question: 'How can I get a GST invoice for my booking?',
      answer:
          'A tax invoice is generated automatically once your trip is completed and is sent to your registered email address. You can also view or download it anytime from the "My Bookings" tab.',
    ),
    _FaqItem(
      category: 'Safety & Policies',
      question: 'Are pets allowed in BroomBoom cabs?',
      answer:
          'Yes! We offer dedicated Pet Cabs. When booking, please choose the Pet Cab option or notify customer support in advance so our pilot is prepared with sanitized seats and pet-friendly accommodations.',
    ),
    _FaqItem(
      category: 'Safety & Policies',
      question: 'What safety measures does BroomBoom take?',
      answer:
          'All our vehicles undergo regular mechanical inspections, and our drivers are background-verified professionals with valid commercial licenses. Every ride is tracked in real-time by our 24x7 control room for your peace of mind.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportSettings();
  }

  Future<void> _loadSupportSettings() async {
    try {
      final email = await SettingsService.getSettingValue('supportEmail');
      final phone = await SettingsService.getSettingValue('supportPhone');
      if (mounted) {
        setState(() {
          if (email != null && email.toString().trim().isNotEmpty) {
            _supportEmail = email.toString().trim();
          }
          if (phone != null && phone.toString().trim().isNotEmpty) {
            _supportPhone = phone.toString().trim();
          }
        });
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label copied to clipboard: $text',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: kInk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          faq.category == _categories[_selectedCategoryIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
        title: Column(
          children: [
            Text(
              'Help & Support',
              style: GoogleFonts.outfit(
                color: kInk,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'BroomBoom Cabs 24x7 Care',
              style: GoogleFonts.outfit(
                color: kAmberDeep,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If opened with a specific booking or bookingId, show context card
            if (widget.booking != null || widget.bookingId != null) ...[
              _buildBookingContextCard(),
              const SizedBox(height: 16),
            ],

            // Hero Brand Support Banner
            _buildSupportHeroBanner(),
            const SizedBox(height: 16),

            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 14),

            // Category Filter Pills
            _buildCategoryPills(),
            const SizedBox(height: 20),

            // FAQs Section Header
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: kAmberDeep, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredFaqs.length} FAQs',
                  style: GoogleFonts.outfit(color: kInkSoft, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FAQ Accordion List
            if (filteredFaqs.isEmpty)
              _buildEmptySearchResults()
            else
              ...filteredFaqs.map((faq) => _buildFaqTile(faq)),

            const SizedBox(height: 28),

            // ── Official Contact Details Section ─────────────────────────────
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  // ── Specific Booking Context Card ──────────────────────────────────────────
  Widget _buildBookingContextCard() {
    final bId = widget.bookingId ??
        widget.booking?.bookingId ??
        (widget.booking?.id != null && widget.booking!.id!.length >= 8
            ? widget.booking!.id!.substring(0, 8).toUpperCase()
            : 'BB-BOOKING');
    final pickup = widget.pickupAddress ?? widget.booking?.pickupAddress ?? 'Pickup Location';
    final drop = widget.dropAddress ?? widget.booking?.dropAddress ?? 'Drop Location';
    final statusText = widget.status ?? widget.booking?.status ?? 'Confirmed';
    final service = widget.vehicleCategory ??
        (widget.booking != null
            ? '${widget.booking!.serviceType} • ${widget.booking!.vehicleCategory}'
            : 'Cab Booking');
    final dateTime = widget.date != null
        ? '${widget.date}${widget.time != null ? " • ${widget.time}" : ""}'
        : (widget.booking != null
            ? '${widget.booking!.pickupDate} • ${widget.booking!.pickupTime}'
            : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAmber.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Booking #$bId',
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kAmberSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    color: kAmberDeep,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 14, color: kAmberDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickup,
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drop,
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service,
                style: GoogleFonts.outfit(color: kInkSoft, fontSize: 11.5),
              ),
              if (dateTime.isNotEmpty)
                Text(
                  dateTime,
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ────────────────────────────────────────────────────────────
  Widget _buildSupportHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF9E6),
            kAmberSoft.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.support_agent_rounded,
                  color: kAmberDeep,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse FAQs below or reach our 24x7 team directly via phone or email.',
                  style: GoogleFonts.outfit(fontSize: 12, color: kInkSoft, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.outfit(fontSize: 14, color: kInk),
        decoration: InputDecoration(
          hintText: 'Search queries (e.g. refund, driver, delay)...',
          hintStyle: GoogleFonts.outfit(color: kInkSoft.withValues(alpha: 0.7), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: kAmberDeep, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: kInkSoft),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Category Pills ─────────────────────────────────────────────────────────
  Widget _buildCategoryPills() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected ? kPrimaryGradient : null,
                color: isSelected ? null : kCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? kAmberDeep : kInputBorder,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: GoogleFonts.outfit(
                    color: isSelected ? kInk : kInkSoft,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── FAQ Accordion Tile ─────────────────────────────────────────────────────
  Widget _buildFaqTile(_FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kAmberSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.question_answer_rounded,
              color: kAmberDeep,
              size: 16,
            ),
          ),
          title: Text(
            faq.question,
            style: GoogleFonts.outfit(
              color: kInk,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: GoogleFonts.outfit(
                  color: kInkSoft,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: kInkSoft.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No matching questions found',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: kInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching a different keyword or contact our support team below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: kInkSoft),
          ),
        ],
      ),
    );
  }

  // ── Official Contact Details Section ───────────────────────────────────────
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: kInk,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BroomBoom Cabs Support',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '24x7 Help Desk Active',
                          style: GoogleFonts.outfit(
                            color: Colors.green.shade700,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Helpline Phone Card
          _buildContactTile(
            icon: Icons.phone_in_talk_rounded,
            title: 'Call BroomBoom Helpline',
            value: _supportPhone,
            actionLabel: 'Copy',
            onTap: () => _copyToClipboard(_supportPhone, 'Phone Number'),
          ),

          const SizedBox(height: 10),

          // Support Email Card
          _buildContactTile(
            icon: Icons.mail_rounded,
            title: 'Official Support Email',
            value: _supportEmail,
            actionLabel: 'Copy',
            onTap: () => _copyToClipboard(_supportEmail, 'Support Email'),
          ),

          const SizedBox(height: 14),
          Center(
            child: Text(
              'Available 24 Hours • 7 Days a Week • Fast Resolution',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: kInkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kBgMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInputBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAmberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kAmberDeep, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: kInkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, color: kInk, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    actionLabel,
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}
