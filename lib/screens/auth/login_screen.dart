import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';
import 'otp_verification_screen.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  bool _isLoading = false;
  bool _agreeToTerms = false;
  Country _selectedCountry = Country.parse('IN');

  // Hover states
  bool _continueHovered = false;
  bool _countryHovered = false;
  bool _termsHovered = false;

  // Entry animation
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideUp = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  // Floating logo animation
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _floatAnim = Tween<double>(
    begin: -6,
    end: 6,
  ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

  // Shimmer sweep across logo
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ───────────────────────────── Logic ─────────────────────────────

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['IN'],
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        backgroundColor: kCardBg,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.78,
        textStyle: GoogleFonts.outfit(fontSize: 15, color: kInk),
        searchTextStyle: GoogleFonts.outfit(fontSize: 15, color: kInk),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Search country',
          labelStyle: GoogleFonts.outfit(color: kInkSoft),
          hintStyle: GoogleFonts.outfit(color: kInkSoft),
          prefixIcon: const Icon(Icons.search, color: kInkSoft),
          filled: true,
          fillColor: kInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kInputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kAmberDeep, width: 2),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  void _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (_phoneController.text.length < 10) {
      _showSnack('Please enter a valid phone number');
      return;
    }

    if (!_agreeToTerms) {
      _showSnack('Please agree to the Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);

    String fullNumber =
        '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    final result = await AuthService.sendOtp(fullNumber);
    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: fullNumber,
            ),
          ),
        );
      } else {
        _showSnack(result.message ?? 'Login failed. Please try again.');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Light Sunny Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBgTop, kBgMid, kBgBottom],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Warm Amber Glow (Top Right) — animated
            Positioned(
              top: -140,
              right: -90,
              child: _animatedGlow(
                size: 380,
                color: kAmber,
                anim: _floatController,
              ),
            ),

            // Soft Orange Glow (Bottom Left) — animated
            Positioned(
              bottom: -160,
              left: -110,
              child: _animatedGlow(
                size: 360,
                color: kAmberDeep,
                anim: _floatController,
                reverse: true,
              ),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Column(
                            children: [
                              const SizedBox(height: 36),
                              _buildLogo(),
                              const SizedBox(height: 28),
                              _buildHeader(),
                              const SizedBox(height: 36),
                              _buildCard(),
                              const SizedBox(height: 24),
                              _buildTermsCheckbox(),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedGlow({
    required double size,
    required Color color,
    required Animation<double> anim,
    bool reverse = false,
  }) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final t = reverse ? (1 - anim.value) : anim.value;
          final scale = 1.0 + (t * 0.12);
          final opacity = 0.18 + (t * 0.14);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: opacity),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── LOGO with float + shimmer ───────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.55),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: kAmberDeep.withValues(alpha: 0.3),
              blurRadius: 70,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 108,
                width: 108,
                fit: BoxFit.cover,
              ),
              // Shimmer sweep
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset(
                          -120 + (_shimmerController.value * 260),
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Welcome to',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: kInkSoft,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFFFFB300), kAmberDeep, Color(0xFFFF6D00)],
              ).createShader(bounds),
          child: Text(
            'BroomBoom Cabs',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your phone number to get started',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 15, color: kInkSoft),
        ),
      ],
    );
  }

  // ── CARD with soft animated hover glow ─────────────────────────────
  Widget _buildCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _continueHovered = _continueHovered),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kInputBorder.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.20),
              blurRadius: 44,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kAmberDeep,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PHONE NUMBER',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: kInkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCountryButton(),
                const SizedBox(width: 12),
                Expanded(child: _buildPhoneField()),
              ],
            ),
            const SizedBox(height: 22),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  // ── Country button with hover effect ───────────────────────────────
  Widget _buildCountryButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _countryHovered = true),
      onExit: (_) => setState(() => _countryHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _countryHovered ? kAmberSoft : kInputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _countryHovered ? kAmberDeep : kInputBorder,
            width: _countryHovered ? 2 : 1,
          ),
          boxShadow:
              _countryHovered
                  ? [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openCountryPicker,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Text(
                  _selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  '+${_selectedCountry.phoneCode}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _countryHovered ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: kInkSoft,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kInk,
        letterSpacing: 0.6,
      ),
      decoration: InputDecoration(
        hintText: 'Phone number',
        hintStyle: GoogleFonts.outfit(
          color: kInkSoft.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kAmberDeep, width: 2),
        ),
      ),
    );
  }

  // ── Continue button with hover (scale + lift + glow) ───────────────
  Widget _buildContinueButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _continueHovered = true),
      onExit: (_) => setState(() => _continueHovered = false),
      child: AnimatedScale(
        scale: _continueHovered && !_isLoading ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: _isLoading ? null : _handleContinue,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient:
                  _isLoading
                      ? null
                      : LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors:
                            _continueHovered
                                ? const [
                                  Color(0xFFFFE082),
                                  Color(0xFFFFB300),
                                  kAmberDeep,
                                ]
                                : const [
                                  Color(0xFFFFD54F),
                                  Color(0xFFFFC107),
                                  kAmberDeep,
                                ],
                      ),
              color: _isLoading ? kAmberSoft : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow:
                  _isLoading
                      ? []
                      : [
                        BoxShadow(
                          color: kAmber.withValues(
                            alpha: _continueHovered ? 0.65 : 0.45,
                          ),
                          blurRadius: _continueHovered ? 32 : 24,
                          offset: Offset(0, _continueHovered ? 14 : 10),
                        ),
                      ],
            ),
            child: Center(
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(kAmberDeep),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kInk,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            offset:
                                _continueHovered
                                    ? const Offset(0.15, 0)
                                    : Offset.zero,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: kInk,
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

  // ── Terms checkbox with hover highlight ────────────────────────────
  Widget _buildTermsCheckbox() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _termsHovered = true),
      onExit: (_) => setState(() => _termsHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                _termsHovered
                    ? kAmberSoft.withValues(alpha: 0.7)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value ?? false);
                  },
                  activeColor: kAmberDeep,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color:
                        _termsHovered
                            ? kAmberDeep
                            : kInkSoft.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Text(
                  'I agree to the Terms & Conditions',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.4,
                    color: _termsHovered ? kAmberDeep : kInkSoft,
                    fontWeight:
                        _termsHovered ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
