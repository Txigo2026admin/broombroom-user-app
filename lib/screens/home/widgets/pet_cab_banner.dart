import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../booking/pet_cab_screen.dart';
import '../../../theme/app_theme.dart';

class PetCabBanner extends StatelessWidget {
  final String phoneNumber;
  const PetCabBanner({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetCabScreen(phoneNumber: phoneNumber),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kAmberSoft,
                shape: BoxShape.circle,
                border: Border.all(color: kInputBorder),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: kAmberDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need a Pet Cab?',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sanitized cabs for your furry friends',
                    style: GoogleFonts.outfit(fontSize: 12, color: kInkSoft),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), kAmber],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kAmber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Book',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: kInk,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
