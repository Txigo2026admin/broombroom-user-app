import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const HomeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(label: 'ONE WAY', icon: Icons.directions_car_rounded),
    _NavItem(label: 'ROUND TRIP', icon: Icons.sync_alt_rounded),
    _NavItem(label: 'LOCAL', icon: Icons.location_city_rounded),
    _NavItem(label: 'AIRPORT', icon: Icons.airplanemode_active_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: kInputBorder.withValues(alpha: 0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: Row(
            children: List<Widget>.generate(
              _items.length,
              (i) => _buildNavItem(i, _items[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isSelected) return;
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 12 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? kPrimaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border:
                isSelected
                    ? Border.all(
                      color: kAmberDeep.withValues(alpha: 0.35),
                      width: 1,
                    )
                    : Border.all(color: Colors.transparent, width: 1),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : const <BoxShadow>[],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: Icon(
                  item.icon,
                  color: isSelected ? kInk : kInkSoft,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.outfit(
                  color: isSelected ? kInk : kInkSoft,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.4,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
