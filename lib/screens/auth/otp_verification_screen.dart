import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _pinFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pinFocusNode.removeListener(_onFocusChange);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final res = await AuthService.sendOtp(widget.phoneNumber);
      if (!mounted) return;

      if (res.success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'New 4-digit OTP sent to your phone!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _pinController.text.trim();

    if (otp.length != 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit OTP code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final result = await AuthService.verifyOtp(widget.phoneNumber, otp);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Mobile number verified successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to HomeScreen and clear auth stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(phoneNumber: widget.phoneNumber),
          ),
          (route) => false,
        );
      } else {
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Invalid OTP. Please check and try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildOtpInputFields() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hidden TextField that captures keyboard, paste, and auto-advance
        Opacity(
          opacity: 0.0,
          child: SizedBox(
            width: 280,
            height: 60,
            child: TextField(
              key: const Key('otp_text_field'),
              controller: _pinController,
              focusNode: _pinFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              autofocus: true,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: (val) {
                setState(() {});
                if (val.length == 4) {
                  _verifyOtp();
                }
              },
            ),
          ),
        ),
        // 4 Stylized OTP Digit Boxes
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _pinFocusNode.requestFocus();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final text = _pinController.text;
              final isFilled = index < text.length;
              final char = isFilled ? text[index] : '';
              final isCurrent = index == text.length;
              final isFocused = _pinFocusNode.hasFocus &&
                  (isCurrent || (index == 3 && text.length == 4));

              return Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFilled
                      ? kAmberSoft.withValues(alpha: 0.45)
                      : (isFocused ? Colors.white : kInputBg),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused
                        ? kAmberDeep
                        : (isFilled ? kAmberDeep : kInputBorder),
                    width: isFocused ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFocused
                          ? kAmber.withValues(alpha: 0.25)
                          : kAmber.withValues(alpha: 0.08),
                      blurRadius: isFocused ? 14 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  char,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: kInk,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Material(
              color: Colors.transparent,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Decorative Icon Badge
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kPrimaryGradient,
                      boxShadow: kButtonShadow(opacity: 0.35),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: kInk,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  "OTP Verification",
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Enter the 4-digit code sent to your mobile number",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: kInkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Number Pill with Edit Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kInputBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 18, color: kInkSoft),
                      const SizedBox(width: 6),
                      Text(
                        widget.phoneNumber,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // Go back to login to edit number
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              "Edit",
                              style: GoogleFonts.outfit(
                                color: kAmberDeep,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 4-Digit Native PIN Input
                _buildOtpInputFields(),

                const SizedBox(height: 32),

                // Resend OTP Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: kInkSoft,
                      ),
                    ),
                    if (_secondsRemaining > 0)
                      Text(
                        "Resend in ${_secondsRemaining}s",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kAmberDeep,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _isResending ? null : _handleResendOtp,
                        child: Text(
                          _isResending ? "Sending..." : "Resend OTP",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kAmberDeep,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 36),

                // Verify & Proceed Button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: kPrimaryButtonDecoration(radius: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isVerifying ? null : _verifyOtp,
                      child: Center(
                        child: _isVerifying
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
                                  Text(
                                    "Verify & Proceed",
                                    style: kButtonTextStyle(size: 17),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: kInk,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
