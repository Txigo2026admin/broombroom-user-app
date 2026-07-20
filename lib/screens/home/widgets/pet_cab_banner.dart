import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../booking/pet_cab_screen.dart';

class PetCabBanner extends StatelessWidget {
  final String phoneNumber;
  const PetCabBanner({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetCabScreen(phoneNumber: phoneNumber)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets, color: Colors.orange.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Need a Pet Cab?',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            Text(
              'Book',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade700, size: 20),
          ],
        ),
      ),
    );
  }
}
