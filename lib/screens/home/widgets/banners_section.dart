import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package_booking_dialog.dart';
import '../../../theme/app_theme.dart';

class BannersSection extends StatelessWidget {
  const BannersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildBannerItem(
            context,
            'CHARDHAM CAB PACKAGES',
            'assets/images/chardham_banner.png',
          ),
          const SizedBox(width: 14),
          _buildBannerItem(
            context,
            'EXPLORE THE BEACHES',
            'assets/images/beach_banner.png',
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(BuildContext context, String title, String imageUrl) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PackageBookingDialog(packageName: title),
        );
      },
      child: Container(
        width: 290,
        height: 154,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.35),
              BlendMode.darken,
            ),
          ),
        ),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
