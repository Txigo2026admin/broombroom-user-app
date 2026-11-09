import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

/// A sleek in-app experience review card inspired by Groww's rating prompt.
///
/// Features:
/// - Gradient card surface with warm glow + soft shadow.
/// - 5 large stars filled with a gold gradient and a soft halo glow.
/// - Animated rating label + optional comment field that expands smoothly.
/// - Gradient "Submit Feedback" CTA with shadow and haptic feedback.
/// - Animated thank-you state showing the user's rating.
/// - Remembers dismissal / submission via `SharedPreferences`.
class ExperienceReviewCard extends StatefulWidget {
  final String appName;
  final VoidCallback? onDismissed;
  final Function(int rating, String comment)? onSubmitted;
  final EdgeInsetsGeometry? margin;
  final bool forceShow;

  const ExperienceReviewCard({
    super.key,
    this.appName = 'BroomBroom',
    this.onDismissed,
    this.onSubmitted,
    this.margin,
    this.forceShow = false,
  });

  /// Displays the review prompt as a modal bottom sheet.
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    String appName = 'BroomBroom',
    Function(int rating, String comment)? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: kInputBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ExperienceReviewCard(
                    appName: appName,
                    margin: EdgeInsets.zero,
                    forceShow: true,
                    onDismissed: () => Navigator.pop(ctx),
                    onSubmitted: (r, c) {
                      onSubmitted?.call(r, c);
                      Future.delayed(const Duration(milliseconds: 1400), () {
                        if (ctx.mounted) Navigator.pop(ctx);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  State<ExperienceReviewCard> createState() => _ExperienceReviewCardState();
}

class _ExperienceReviewCardState extends State<ExperienceReviewCard> {
  static const String _prefKeyDismissed = 'bb_experience_review_dismissed';

  int _selectedRating = 0;
  bool _submitted = false;
  bool _isDismissed = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.forceShow) _checkIfDismissed();
  }

  Future<void> _checkIfDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_prefKeyDismissed) ?? false;
      if (dismissed && mounted) setState(() => _isDismissed = true);
    } catch (_) {}
  }

  Future<void> _dismissCard() async {
    HapticFeedback.selectionClick();
    setState(() => _isDismissed = true);
    widget.onDismissed?.call();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyDismissed, true);
    } catch (_) {}
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
    widget.onSubmitted?.call(_selectedRating, _commentController.text.trim());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyDismissed, true);
    } catch (_) {}
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Loved it! 😍';
      case 4:
        return 'Great experience! 😊';
      case 3:
        return 'It was okay 🙂';
      case 2:
        return 'Could be better 😕';
      case 1:
        return 'Not a great experience 😞';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
      case 4:
        return const Color(0xFF1B8A5A);
      case 3:
        return kAmberDeep;
      case 2:
        return const Color(0xFFE07A1F);
      default:
        return const Color(0xFFD64545);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin:
            widget.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kCardBg,
              Color.alphaBlend(kAmberSoft.withValues(alpha: 0.35), kCardBg),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kAmber.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _submitted ? _buildThankYouState() : _buildReviewContent(),
      ),
    );
  }

  // ---------- Review content ----------

  Widget _buildReviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStarRow(),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _selectedRating == 0 ? _buildHint() : _buildRatedSection(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'How is your experience with ${widget.appName}?',
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: kInk,
              height: 1.28,
              letterSpacing: -0.25,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: kInputBg.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _dismissCard,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 18, color: kInkSoft),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) => _buildStar(i + 1)),
      ),
    );
  }

  Widget _buildStar(int starIndex) {
    final isFilled = starIndex <= _selectedRating;
    final isSelected = starIndex == _selectedRating;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedRating = starIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : (isFilled ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow:
                  isFilled
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFFB300,
                          ).withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                      : const <BoxShadow>[],
            ),
            child:
                isFilled
                    ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback:
                          (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                          ).createShader(rect),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      Icons.star_outline_rounded,
                      size: 40,
                      color: const Color(0xFF9E9E9E).withValues(alpha: 0.65),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Center(
        child: Text(
          'Tap a star to rate your experience',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: kInkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRatedSection() {
    final color = _getRatingColor(_selectedRating);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
            child: Text(
              _getRatingLabel(_selectedRating),
              key: ValueKey<int>(_selectedRating),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 2,
            minLines: 1,
            style: GoogleFonts.outfit(fontSize: 13.5, color: kInk, height: 1.4),
            decoration: InputDecoration(
              hintText:
                  _selectedRating >= 4
                      ? 'What did you like most? (optional)'
                      : 'How can we improve? (optional)',
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: kInkSoft),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: kInputBg,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: kInputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: kInputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kAmberDeep, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB300), Color(0xFFFF8A00)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kAmberDeep.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _submitFeedback,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Submit Feedback',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Thank-you state ----------

  Widget _buildThankYouState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.4),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Thank You for Your Feedback!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kInk,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps us make ${widget.appName} better for you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: kInkSoft,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (_selectedRating > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final filled = i < _selectedRating;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color:
                        filled
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF9E9E9E).withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
