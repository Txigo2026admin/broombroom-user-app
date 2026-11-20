import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

/// Keeps a single digit in a box. If several digits arrive at once (paste /
/// SMS autofill) they are handed to [onPaste] so they can be spread across
/// the remaining boxes instead of being thrown away.
class _OtpDigitInputFormatter extends TextInputFormatter {
  _OtpDigitInputFormatter({required this.onPaste});

  final ValueChanged<String> onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (digits.length > 1) {
      onPaste(digits);
      return oldValue;
    }

    // Always keep the caret after the single digit so typing over a filled
    // box simply replaces its value.
    return TextEditingValue(
      text: digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 4;

  /// One controller + one focus node per box, so every box can be edited
  /// independently and in any order.
  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;

  Timer? _resendTimer;
  int _secondsRemaining = 30;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (var i = 0; i < _otpLength; i++) {
      _otpFocusNodes[i].addListener(_onBoxFocusChange);
    }
  }

  void _onBoxFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final node in _otpFocusNodes) {
      node.removeListener(_onBoxFocusChange);
      node.dispose();
    }
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // OTP helpers
  // ---------------------------------------------------------------------------

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete =>
      _otpControllers.every((c) => c.text.trim().isNotEmpty);

  /// Focus a specific box (used by taps, auto-advance and back-space hop).
  void _focusBox(int index) {
    if (index < 0 || index >= _otpLength) return;
    _otpFocusNodes[index].requestFocus();
  }

  void _onOtpChanged(int index, String value) {
    setState(() {});

    // Box was emptied -> hop back so the user can keep deleting.
    if (value.isEmpty) {
      if (index > 0) _focusBox(index - 1);
      return;
    }

    // All boxes filled -> verify straight away.
    if (_isOtpComplete) {
      FocusScope.of(context).unfocus();
      if (!_isVerifying) _verifyOtp();
      return;
    }

    // Otherwise jump to the next box (skips nothing – the user can still
    // tap any box at any time).
    if (index < _otpLength - 1) {
      _focusBox(index + 1);
    }
  }

  /// Called from the formatter when a multi-digit string is pasted.
  void _handlePaste(String digits) {
    // The formatter runs inside the text-input update, so defer the state
    // mutation to the next micro-task.
    Future.microtask(() {
      if (!mounted) return;
      _fillOtp(digits);
    });
  }

  void _fillOtp(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _otpLength; i++) {
      _otpControllers[i].text = i < clean.length ? clean[i] : '';
    }
    setState(() {});

    if (_isOtpComplete) {
      FocusScope.of(context).unfocus();
      if (!_isVerifying) _verifyOtp();
    } else {
      _focusBox(clean.length.clamp(0, _otpLength - 1));
    }
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    if (!mounted) return;
    setState(() {});
    _focusBox(0);
  }

  // ---------------------------------------------------------------------------
  // Resend timer
  // ---------------------------------------------------------------------------

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

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final res = await AuthService.sendOtp(widget.phoneNumber);
      if (!mounted) return;

      if (res.success) {
        _startResendTimer();
        _clearOtp();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'New 4-digit OTP sent to your phone!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ?? 'Failed to resend OTP. Please try again.',
            ),
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

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final otp = _otpCode;

    if (!_isOtpComplete || otp.length != _otpLength) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit OTP code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isVerifying = true);

    try {
      final result = await AuthService.verifyOtp(widget.phoneNumber, otp);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Mobile number verified successfully!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(phoneNumber: widget.phoneNumber),
          ),
          (route) => false,
        );
      } else {
        _clearOtp();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Invalid OTP. Please check and try again.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _clearOtp();
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _buildOtpInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (index) {
        final isFilled = _otpControllers[index].text.isNotEmpty;
        final isFocused = _otpFocusNodes[index].hasFocus;

        return GestureDetector(
          key: Key('otp_box_$index'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _focusBox(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isFilled
                      ? kAmberSoft.withValues(alpha: 0.45)
                      : (isFocused ? Colors.white : kInputBg),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isFocused
                        ? kAmberDeep
                        : (isFilled ? kAmberDeep : kInputBorder),
                width: isFocused ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isFocused
                          ? kAmber.withValues(alpha: 0.25)
                          : kAmber.withValues(alpha: 0.08),
                  blurRadius: isFocused ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              key: Key('otp_field_$index'),
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textInputAction:
                  index == _otpLength - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
              textAlign: TextAlign.center,
              cursorColor: kAmberDeep,
              cursorWidth: 2,
              enableSuggestions: false,
              autocorrect: false,
              enableInteractiveSelection: false,
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: kInk,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [_OtpDigitInputFormatter(onPaste: _handlePaste)],
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (value) => _onOtpChanged(index, value),
              onSubmitted: (_) {
                if (_isOtpComplete && !_isVerifying) _verifyOtp();
              },
            ),
          ),
        );
      }),
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
                      const Icon(
                        Icons.phone_iphone_rounded,
                        size: 18,
                        color: kInkSoft,
                      ),
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
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
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

                // 4 independent OTP boxes – tap any box to fill it
                _buildOtpInputFields(),

                const SizedBox(height: 32),

                // Resend OTP Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: GoogleFonts.outfit(fontSize: 14, color: kInkSoft),
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
                        child:
                            _isVerifying
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
    );
  }
}
