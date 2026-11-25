import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Interactive 4-step progress indicator for the booking flow:
/// Step 1: Search -> Step 2: Select Cab -> Step 3: Review -> Step 4: Payment
class BookingStepsBar extends StatelessWidget {
  final int currentStep; // 1 to 4
  final bool allCompleted;
  final VoidCallback? onStep1Tap;
  final VoidCallback? onStep2Tap;
  final VoidCallback? onStep3Tap;

  const BookingStepsBar({
    super.key,
    required this.currentStep,
    this.allCompleted = false,
    this.onStep1Tap,
    this.onStep2Tap,
    this.onStep3Tap,
  });

  static const List<String> _labels = [
    'Search',
    'Select Cab',
    'Review',
    'Payment',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(
          bottom: BorderSide(color: kInputBorder.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _labels.length; i++) ...[
            _buildStepItem(context, i + 1, _labels[i]),
            if (i < _labels.length - 1) _buildConnector(i + 1),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, int stepNumber, String label) {
    final bool isCompleted = allCompleted || stepNumber < currentStep;
    final bool isActive = !allCompleted && stepNumber == currentStep;

    VoidCallback? onTap;
    if (isCompleted && !allCompleted) {
      if (stepNumber == 1) {
        onTap =
            onStep1Tap ??
            () => Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (stepNumber == 2) {
        onTap = onStep2Tap;
      } else if (stepNumber == 3) {
        onTap = onStep3Tap;
      }
    }

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? kPrimaryGradient : null,
            color:
                isCompleted
                    ? const Color(0xFF2E7D32)
                    : (isActive ? null : kInputBg),
            border: Border.all(
              color:
                  isCompleted
                      ? const Color(0xFF2E7D32)
                      : (isActive ? kAmberDeep : kInputBorder),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          alignment: Alignment.center,
          child:
              isCompleted
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                    '$stepNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isActive ? kInk : kInkSoft,
                    ),
                  ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight:
                (isActive || isCompleted) ? FontWeight.w700 : FontWeight.w500,
            color:
                isCompleted
                    ? const Color(0xFF2E7D32)
                    : (isActive ? kInk : kInkSoft),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: content,
    );
  }

  Widget _buildConnector(int leftStepNumber) {
    final bool isDone = allCompleted || leftStepNumber < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14, left: 2, right: 2),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF2E7D32) : kInputBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
