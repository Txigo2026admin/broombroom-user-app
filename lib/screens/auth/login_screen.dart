import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';
import '../../utils/url_launcher_helper.dart';
import 'otp_verification_screen.dart';
import '../home/home_screen.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _agreeToTerms = false;
  Country _selectedCountry = Country.parse('IN');

  // Hover states
  bool _continueHovered = false;
  bool _googleHovered = false;
  bool _countryHovered = false;
  bool _termsHovered = false;

  late final TapGestureRecognizer _termsRecognizer =
      TapGestureRecognizer()
        ..onTap =
            () => _launchWebUrl('https://www.broomboomcabs.com/user-terms');
  late final TapGestureRecognizer _privacyRecognizer =
      TapGestureRecognizer()
        ..onTap =
            () => _launchWebUrl('https://www.broomboomcabs.com/privacy-policy');

  bool get _isIndia => AuthService.isIndiaCountry(
    countryCode: _selectedCountry.countryCode,
    phoneCode: _selectedCountry.phoneCode,
  );

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
    _emailController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
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

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (!_isIndia) {
      await _handleEmailLogin();
      return;
    }

    if (_phoneController.text.length < 10) {
      _showSnack('Please enter a valid phone number');
      return;
    }

    if (!_agreeToTerms) {
      _showSnack('Please agree to the Terms & Condition and Privacy Policy');
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
            builder:
                (context) => OtpVerificationScreen(phoneNumber: fullNumber),
          ),
        );
      } else {
        _showSnack(result.message ?? 'Login failed. Please try again.');
      }
    }
  }

  /// Validates optional phone entry for outside-India countries.
  /// Returns `''` when omitted, `'+<code><digits>'` when valid, or `null` if invalid.
  String? _resolveOptionalInternationalPhone() {
    final digits = _phoneController.text.trim();
    if (digits.isEmpty) return '';
    if (digits.length < 6 || digits.length > 15) {
      _showSnack(
        'Please enter a valid mobile number (6 to 15 digits) or leave it blank.',
      );
      return null;
    }
    return '+${_selectedCountry.phoneCode}$digits';
  }

  Future<void> _handleEmailLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      _showSnack('Please enter a valid email address');
      _emailFocus.requestFocus();
      return;
    }

    final optionalPhone = _resolveOptionalInternationalPhone();
    if (optionalPhone == null) return;

    if (!_agreeToTerms) {
      _showSnack('Please agree to the Terms & Condition and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.loginWithEmail(
      email: email,
      name: _nameController.text.trim(),
      phone: optionalPhone,
      countryCode: _selectedCountry.countryCode,
      dialCode: '+${_selectedCountry.phoneCode}',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _navigateToHome(result.phoneNumber);
    } else {
      _showSnack(result.message ?? 'Email login failed. Please try again.');
    }
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();

    final optionalPhone = _resolveOptionalInternationalPhone();
    if (optionalPhone == null) return;

    if (!_agreeToTerms) {
      _showSnack('Please agree to the Terms & Condition and Privacy Policy');
      return;
    }

    setState(() => _isGoogleLoading = true);

    final result = await AuthService.signInWithGoogle(
      phone: optionalPhone,
      countryCode: _selectedCountry.countryCode,
      dialCode: '+${_selectedCountry.phoneCode}',
    );

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success) {
      _navigateToHome(result.phoneNumber);
    } else if (result.needsGoogleConfig) {
      _showGoogleSetupDialog(result.message);
    } else {
      _showSnack(result.message ?? 'Google sign-in failed. Please try again.');
    }
  }

  void _navigateToHome(String phoneNumber) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(phoneNumber: phoneNumber),
      ),
      (route) => false,
    );
  }

  void _showGoogleSetupDialog(String? message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: kCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Google Sign-In Setup Needed',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            content: Text(
              message ??
                  'Google OAuth Client ID is not configured yet for this app build. You can verify using your Email ID right now.',
              style: GoogleFonts.outfit(color: kInkSoft, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(color: kInkSoft),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAmber,
                  foregroundColor: kInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _emailFocus.requestFocus();
                },
                child: Text(
                  'Use Email ID',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _launchWebUrl(String urlString) async {
    try {
      final launched = await UrlLauncherHelper.openUrl(urlString);
      if (!launched && mounted) {
        _showSnack('Could not open link');
      }
    } catch (e) {
      debugPrint('Error launching URL $urlString: $e');
      if (mounted) {
        _showSnack('Could not open link');
      }
    }
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
                  _isIndia ? 'PHONE NUMBER' : 'MOBILE NUMBER (OPTIONAL)',
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
            if (_isIndia) ...[
              const SizedBox(height: 22),
              _buildContinueButton(),
            ] else ...[
              const SizedBox(height: 14),
              _buildOutsideIndiaSection(),
            ],
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

  Widget _buildOutsideIndiaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kAmberSoft.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kInputBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: kAmberDeep,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No SMS OTP needed outside India. Verify using Email ID or Google.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('EMAIL ID'),
        const SizedBox(height: 8),
        _buildStyledTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          hintText: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('FULL NAME (OPTIONAL)'),
        const SizedBox(height: 8),
        _buildStyledTextField(
          controller: _nameController,
          hintText: 'Enter your name',
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildPrimaryActionButton(
          label: 'Continue with Email',
          isLoading: _isLoading,
          onTap: (_isLoading || _isGoogleLoading) ? null : _handleEmailLogin,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Divider(color: kInputBorder.withValues(alpha: 0.9)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kInkSoft,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: kInputBorder.withValues(alpha: 0.9)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildGoogleButton(),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Row(
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
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: kInkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    required TextInputType keyboardType,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          color: kInkSoft.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, color: kAmberDeep, size: 20),
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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

  Widget _buildGoogleButton() {
    final disabled = _isLoading || _isGoogleLoading;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _googleHovered = true),
      onExit: (_) => setState(() => _googleHovered = false),
      child: AnimatedScale(
        scale: _googleHovered && !disabled ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: disabled ? null : _handleGoogleLogin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _googleHovered && !disabled ? kInputBg : kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _googleHovered ? kAmberDeep : kInputBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child:
                  _isGoogleLoading
                      ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(kAmberDeep),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Center(
                              child: CustomPaint(
                                size: const Size(16, 16),
                                painter: _GoogleLogoPainter(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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

  // ── Continue button with hover (scale + lift + glow) ───────────────
  Widget _buildContinueButton() {
    return _buildPrimaryActionButton(
      label: 'Continue',
      isLoading: _isLoading,
      onTap: _isLoading ? null : _handleContinue,
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _continueHovered = true),
      onExit: (_) => setState(() => _continueHovered = false),
      child: AnimatedScale(
        scale: _continueHovered && !isLoading ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient:
                  isLoading
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
              color: isLoading ? kAmberSoft : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow:
                  isLoading
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
                  isLoading
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
                            label,
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.4,
                        color: _termsHovered ? kAmberDeep : kInkSoft,
                        fontWeight:
                            _termsHovered ? FontWeight.w600 : FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.4,
                            color: kAmberDeep,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: kAmberDeep,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.4,
                            color: kAmberDeep,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: kAmberDeep,
                          ),
                          recognizer: _privacyRecognizer,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.22;
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(strokeWidth / 2);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;

    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.55, 1.85, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.35, 1.4, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.55, 1.85, false, paint);

    // Blue right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.1, 0.72, false, paint);

    // Blue horizontal bar
    final barPaint =
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
    final double cy = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.5, cy),
      Offset(size.width * 0.96, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
