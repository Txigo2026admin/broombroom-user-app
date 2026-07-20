import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';
import '../auth/login_screen.dart';

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
            bottom: 60,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/mandala_footer.png',
              fit: BoxFit.cover,
              color: Colors.grey.withOpacity(0.05),
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
                const SizedBox(height: 24),
                _buildInputField('MOBILE', widget.phoneNumber),
                const SizedBox(height: 24),
                _buildInputField('EMAIL', _email),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(color: Colors.amber.shade400, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Delete Account',
                        style: GoogleFonts.outfit(color: Colors.grey),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.amber.shade400,
              child: Column(
                children: [
                  Text(
                    'For any feedback or concerns related to your booking, please',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'mail us at $_supportEmail, or call us at ',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 11),
                      ),
                      const Icon(Icons.call, color: Colors.white, size: 12),
                      Text(
                        ' $_supportPhone.',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            hintText: value,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber.shade400)),
          ),
          style: GoogleFonts.outfit(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }
}
