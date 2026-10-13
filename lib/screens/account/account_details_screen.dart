import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';
import '../auth/login_screen.dart';
import '../../theme/app_theme.dart';

class AccountDetailsScreen extends StatefulWidget {
  final String phoneNumber;
  const AccountDetailsScreen({super.key, required this.phoneNumber});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  String _userName = 'Loading...';
  String _email = 'Loading...';
  String _supportEmail = 'orders@savaari.com';
  String _supportPhone = '5913506266';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Enter your name';
      _email = prefs.getString('user_email') ?? 'Enter your email';
    });
  }

  Future<void> _loadSettings() async {
    final email = await SettingsService.getSettingValue('supportEmail');
    final phone = await SettingsService.getSettingValue('supportPhone');
    if (mounted) {
      setState(() {
        if (email != null) _supportEmail = email;
        if (phone != null) _supportPhone = phone;
      });
    }
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

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
          'Account Details',
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
            bottom: 60,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/mandala_footer.png',
              fit: BoxFit.cover,
              color: kAmber.withValues(alpha: 0.06),
              colorBlendMode: BlendMode.dstIn,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField('NAME', _userName),
                const SizedBox(height: 18),
                _buildInputField('MOBILE', widget.phoneNumber),
                const SizedBox(height: 18),
                _buildInputField('EMAIL', _email),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: kButtonShadow(),
                    ),
                    child: Center(
                      child: Text(
                        'Update Details',
                        style: GoogleFonts.outfit(color: kInk, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, color: kAmberDeep, size: 18),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(color: kAmberDeep, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Delete Account',
                        style: GoogleFonts.outfit(color: kInkSoft),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Footer Info Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: kAmberSoft,
                border: Border(top: BorderSide(color: kInputBorder)),
              ),
              child: Column(
                children: [
                  Text(
                    'For any feedback or concerns related to your booking, please',
                    style: GoogleFonts.outfit(color: kInkSoft, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'mail us at $_supportEmail, or call us at ',
                        style: GoogleFonts.outfit(color: kInk, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.call_rounded, color: kAmberDeep, size: 13),
                      Text(
                        ' $_supportPhone.',
                        style: GoogleFonts.outfit(
                          color: kAmberDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: kAmberDeep,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: value,
              hintStyle: GoogleFonts.outfit(color: kInkSoft.withValues(alpha: 0.6)),
              border: InputBorder.none,
            ),
            style: GoogleFonts.outfit(color: kInk, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

