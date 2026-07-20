import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package_booking_dialog.dart';

class BannersSection extends StatelessWidget {
  const BannersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildBannerItem(context, 'CHARDHAM CAB PACKAGES', 'assets/images/chardham_banner.png'),
          const SizedBox(width: 12),
          _buildBannerItem(context, 'EXPLORE THE BEACHES', 'assets/images/beach_banner.png'),
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
        width: 280,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
