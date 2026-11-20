import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

/// A sleek in-app experience review card inspired by Groww's rating prompt.
///
/// Can be presented as:
/// - A center modal pop-up dialog via [ExperienceReviewCard.showPopup]
/// - A bottom sheet modal via [ExperienceReviewCard.showAsBottomSheet]
/// - An inline widget (e.g. on the thank-you screen)
class ExperienceReviewCard extends StatefulWidget {
  final String appName;
  final VoidCallback? onDismissed;
  final Function(int rating, String comment)? onSubmitted;
  final EdgeInsetsGeometry? margin;
  final bool forceShow;
  final bool isPopup;

  const ExperienceReviewCard({
    super.key,
    this.appName = 'BroomBoom cabs',
    this.onDismissed,
    this.onSubmitted,
    this.margin,
    this.forceShow = false,
    this.isPopup = false,
  });

  /// Clears stored dismissal from SharedPreferences so the popup can show again.
  static Future<void> resetDismissal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ExperienceReviewCardState._prefKeyDismissed);
      await prefs.remove(_ExperienceReviewCardState._prefKeySubmitted);
      await prefs.remove(_ExperienceReviewCardState._legacyPrefKeyDismissed);
    } catch (_) {}
  }

  /// Displays the review prompt as an elegant center pop-up dialog.
  static Future<void> showPopup(
    BuildContext context, {
    String appName = 'BroomBoom cabs',
    Function(int rating, String comment)? onSubmitted,
    VoidCallback? onDismissed,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder:
          (ctx) => PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                onDismissed?.call();
              }
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ExperienceReviewCard(
                    appName: appName,
                    margin: EdgeInsets.zero,
                    forceShow: true,
                    isPopup: true,
                    onDismissed: () {
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true).maybePop();
                      }
                      onDismissed?.call();
                    },
                    onSubmitted: (r, c) {
                      onSubmitted?.call(r, c);
                      Future.delayed(const Duration(milliseconds: 1400), () {
                        if (ctx.mounted) {
                          Navigator.of(ctx, rootNavigator: true).maybePop();
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
    );
  }

  /// Alias for `showPopup` for convenience.
  static Future<void> showAsDialog(
    BuildContext context, {
    String appName = 'BroomBroom',
    Function(int rating, String comment)? onSubmitted,
    VoidCallback? onDismissed,
    bool barrierDismissible = true,
  }) => showPopup(
    context,
    appName: appName,
    onSubmitted: onSubmitted,
    onDismissed: onDismissed,
    barrierDismissible: barrierDismissible,
  );

  /// Checks SharedPreferences and triggers the popup dialog if not dismissed or submitted recently.
  static Future<bool> checkAndShowPopup(
    BuildContext context, {
    String appName = 'BroomBoom cabs',
    Function(int rating, String comment)? onSubmitted,
    bool forceShow = false,
  }) async {
    if (!context.mounted) return false;
    if (!forceShow) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final submittedAt =
            prefs.getInt(_ExperienceReviewCardState._prefKeySubmitted) ?? 0;
        if (submittedAt > 0) return false;

        final dismissedAt =
            prefs.getInt(_ExperienceReviewCardState._prefKeyDismissed) ?? 0;
        if (dismissedAt > 0) {
          final diff = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(dismissedAt),
          );
          if (diff.inDays < 3) return false;
        }
      } catch (_) {}
    }

    if (!context.mounted) return false;
    await showPopup(context, appName: appName, onSubmitted: onSubmitted);
    return true;
  }

  /// Displays the review prompt as a modal bottom sheet.
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    String appName = 'BroomBoom cabs',
    Function(int rating, String comment)? onSubmitted,
    VoidCallback? onDismissed,
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
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
                        isPopup: true,
                        onDismissed: () {
                          if (ctx.mounted) {
                            Navigator.of(ctx, rootNavigator: true).maybePop();
                          }
                          onDismissed?.call();
                        },
                        onSubmitted: (r, c) {
                          onSubmitted?.call(r, c);
                          Future.delayed(
                            const Duration(milliseconds: 1400),
                            () {
                              if (ctx.mounted) {
                                Navigator.of(
                                  ctx,
                                  rootNavigator: true,
                                ).maybePop();
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  State<ExperienceReviewCard> createState() => _ExperienceReviewCardState();
}

class _ExperienceReviewCardState extends State<ExperienceReviewCard> {
  static const String _prefKeyDismissed =
      'bb_experience_review_popup_v1_dismissed_at';
  static const String _prefKeySubmitted =
      'bb_experience_review_popup_v1_submitted_at';
  static const String _legacyPrefKeyDismissed =
      'bb_experience_review_v2_dismissed_at';

  int _selectedRating = 0;
  bool _submitted = false;
  bool _isDismissed = false;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    if (!widget.forceShow) {
      _checkIfDismissed();
    }
  }

  Future<void> _checkIfDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedAt = prefs.getInt(_prefKeyDismissed) ?? 0;
      if (dismissedAt > 0) {
        final days =
            DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(dismissedAt))
                .inDays;
        if (days < 3 && mounted) {
          setState(() => _isDismissed = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _dismissCard() async {
    HapticFeedback.selectionClick();
    setState(() => _isDismissed = true);
    widget.onDismissed?.call();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _prefKeyDismissed,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
    if (widget.isPopup && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
    widget.onSubmitted?.call(_selectedRating, _commentController.text.trim());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _prefKeySubmitted,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt(
        _prefKeyDismissed,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
    if (widget.isPopup) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      });
    }
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
        return 'Disappointing 😞';
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.isPopup ? 22 : 16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.isPopup ? 0.12 : 0.04,
              ),
              blurRadius: widget.isPopup ? 24 : 14,
              offset: Offset(0, widget.isPopup ? 8 : 4),
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
        const SizedBox(height: 18),
        _buildStarRow(),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _selectedRating == 0
                  ? const SizedBox.shrink()
                  : _buildRatedSection(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: kAmberSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.star_rounded, color: kAmberDeep, size: 24),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How is your experience?',
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2530),
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rate your ride with ${widget.appName}',
                style: GoogleFonts.outfit(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: kInkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkResponse(
          onTap: _dismissCard,
          radius: 18,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF64748B),
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
        final wasPositive = _selectedRating >= 4;
        final isNowPositive = starIndex >= 4;
        if (wasPositive != isNowPositive) {
          _selectedTags.clear();
          _commentController.clear();
        }
        setState(() => _selectedRating = starIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: AnimatedScale(
          scale: isSelected ? 1.16 : (isFilled ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child:
              isFilled
                  ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback:
                        (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFCA28), Color(0xFFFF9800)],
                        ).createShader(rect),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(
                    Icons.star_outline_rounded,
                    size: 42,
                    color: Color(0xFF8C95A6),
                  ),
        ),
      ),
    );
  }

  Widget _buildRatedSection() {
    final color = _getRatingColor(_selectedRating);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
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
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickChips(),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 2,
            minLines: 1,
            style: GoogleFonts.outfit(fontSize: 13.5, color: kInk, height: 1.4),
            decoration: InputDecoration(
              hintText:
                  _selectedRating >= 4
                      ? 'What did you like most? (optional)'
                      : 'Tell us how we can improve (optional)',
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: kInkSoft),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                    fontSize: 14.0,
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

  Widget _buildQuickChips() {
    final List<String> tags =
        _selectedRating >= 4
            ? const [
              'Punctual Pilot',
              'Clean & Fresh Cab',
              'Polite Behavior',
              'Smooth Ride',
              'Great Pricing',
              'Easy App Experience',
            ]
            : const [
              'Delayed Pickup',
              'Cab Not Clean',
              'AC / Comfort Issue',
              'Driver Behavior',
              'Fare Concern',
              'App / Map Issue',
            ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                  if (_selectedTags.isNotEmpty) {
                    _commentController.text = _selectedTags.join(', ');
                  } else {
                    _commentController.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFFFFF3CD)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kAmberDeep : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.2 : 1.0,
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.outfit(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected
                            ? const Color(0xFF8B5A00)
                            : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
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
