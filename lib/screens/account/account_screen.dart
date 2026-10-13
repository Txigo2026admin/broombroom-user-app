import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_details_screen.dart';
import 'bookings_screen.dart';
import 'content_hub_screen.dart';
import '../../theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  final String phoneNumber;
  const AccountScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: GoogleFonts.outfit(
            color: kInk,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Decorative Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/mandala_footer.png',
              fit: BoxFit.cover,
              color: kAmber.withValues(alpha: 0.08),
              colorBlendMode: BlendMode.dstIn,
            ),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Profile Picture
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kInputBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kAmber.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 44,
                        backgroundColor: kAmberSoft,
                        child: Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: kAmberDeep,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Menu Items
                  _buildMenuItem(
                    context,
                    'My bookings',
                    Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMenuItem(
                    context,
                    'Account details',
                    Icons.manage_accounts_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMenuItem(
                    context,
                    'Road trips for you',
                    Icons.explore_rounded,
                  ),
                  const Spacer(),
                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(Icons.flutter_dash),
                      const SizedBox(width: 18),
                      _buildSocialIcon(Icons.facebook_rounded),
                      const SizedBox(width: 18),
                      _buildSocialIcon(Icons.camera_alt_rounded),
                      const SizedBox(width: 18),
                      _buildSocialIcon(Icons.play_circle_fill_rounded),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
        boxShadow: kCardShadow(opacity: 0.12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAmberSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kInputBorder),
          ),
          child: Icon(icon, color: kAmberDeep, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kInk,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: kAmberDeep,
        ),
        onTap: () {
          Widget nextScreen;
          if (title == 'My bookings') {
            nextScreen = const BookingsScreen();
          } else if (title == 'Account details') {
            nextScreen = AccountDetailsScreen(phoneNumber: phoneNumber);
          } else {
            nextScreen = const ContentHubScreen();
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        },
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kCardBg,
        border: Border.all(color: kInputBorder),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: kAmberDeep, size: 22),
    );
  }
}
