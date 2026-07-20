import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/booking_card.dart';
import 'widgets/banners_section.dart';
import 'widgets/expert_section.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/pet_cab_banner.dart';
import 'widgets/airport_booking_card.dart';
import 'widgets/local_booking_card.dart';
import '../account/account_screen.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  const HomeScreen({super.key, this.phoneNumber = '919243424225'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  bool _isOneWay = true;

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 2:
        return 'Local Hourly Rentals';
      case 3:
        return 'Airport Cabs';
      default:
        return 'Broom Boom Cabs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountScreen(phoneNumber: widget.phoneNumber),
                  ),
                );
              },
              child: Icon(Icons.account_circle, color: Colors.amber.shade400, size: 32),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBookingCard(),
            PetCabBanner(phoneNumber: widget.phoneNumber),
            const BannersSection(),
            const ExpertSection(),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
            if (index == 0) {
              _isOneWay = true;
            } else if (index == 1) {
              _isOneWay = false;
            }
          });
        },
      ),
    );
  }

  Widget _buildBookingCard() {
    switch (_selectedNavIndex) {
      case 2:
        return const LocalBookingCard();
      case 3:
        return const AirportBookingCard();
      default:
        return BookingCard(
          isOneWay: _isOneWay,
          onToggle: (val) => setState(() => _isOneWay = val),
          phoneNumber: widget.phoneNumber,
        );
    }
  }
}
