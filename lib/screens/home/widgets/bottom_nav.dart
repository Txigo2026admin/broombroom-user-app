import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const HomeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'ONE WAY', Icons.directions_car_outlined),
          _buildNavItem(1, 'ROUND TRIP', Icons.sync),
          _buildNavItem(2, 'LOCAL', Icons.location_city_outlined),
          _buildNavItem(3, 'AIRPORT', Icons.airplanemode_active),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          border: Border(top: BorderSide(color: isSelected ? Colors.amber : Colors.transparent, width: 2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
