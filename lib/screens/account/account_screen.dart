import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_details_screen.dart';
import 'bookings_screen.dart';
import 'content_hub_screen.dart';

class AccountScreen extends StatelessWidget {
  final String phoneNumber;
  const AccountScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
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
              color: Colors.grey.withOpacity(0.1),
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
                        border: Border.all(color: Colors.amber.shade100, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.amber.shade50,
                        child: Icon(Icons.person, size: 50, color: Colors.amber.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Menu Items
                  _buildMenuItem(context, 'My bookings'),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Account details'),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Road trips for you'),
                  const Spacer(),
                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(Icons.flutter_dash), // Mock Twitter
                      const SizedBox(width: 20),
                      _buildSocialIcon(Icons.facebook),
                      const SizedBox(width: 20),
                      _buildSocialIcon(Icons.camera_alt_outlined), // Mock Instagram
                      const SizedBox(width: 20),
                      _buildSocialIcon(Icons.play_circle_outline), // Mock YouTube
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward, size: 18, color: Colors.black54),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, color: Colors.black87, size: 24),
    );
  }
}
