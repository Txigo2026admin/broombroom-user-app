import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/booking_card.dart';
import 'widgets/banners_section.dart';
import 'widgets/expert_section.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/pet_cab_banner.dart';
import 'widgets/airport_booking_card.dart';
import 'widgets/local_booking_card.dart';
import '../../theme/app_theme.dart';
import '../account/account_screen.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  final int initialNavIndex;
  const HomeScreen({
    super.key,
    this.phoneNumber = '919243424225',
    this.initialNavIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedNavIndex;
  bool _isOneWay = true;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    if (_selectedNavIndex == 1) {
      _isOneWay = false;
    }
  }

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 2:
        return 'Local Rentals';
      case 3:
        return 'Airport Cabs';
      default:
        return 'BroomBoom Cabs';
    }
  }

  String _getAppBarSubtitle() {
    switch (_selectedNavIndex) {
      case 2:
        return 'Hourly packages for your city';
      case 3:
        return 'On-time airport transfers';
      default:
        return 'Ride anywhere, anytime';
    }
  }

  IconData _getAppBarIcon() {
    switch (_selectedNavIndex) {
      case 2:
        return Icons.location_city_rounded;
      case 3:
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.local_taxi_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: _buildAppBar(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildBookingCard(),
            PetCabBanner(phoneNumber: widget.phoneNumber),
            const SizedBox(height: 4),
            const BannersSection(),
            const SizedBox(height: 4),
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

  // ───────────────────────────────────────────────────────────────────
  //  Beautiful branded AppBar
  // ───────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFBF2)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(
            color: kInputBorder.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(
            children: [
              // ── Gradient brand tile with car icon ─────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kAmberDeep.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: kButtonShadow(opacity: 0.35),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                  child: Icon(
                    _getAppBarIcon(),
                    key: ValueKey<int>(_selectedNavIndex),
                    color: kInk,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Title + dynamic subtitle ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder:
                          (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                      child: Text(
                        _getAppBarTitle(),
                        key: ValueKey<String>(_getAppBarTitle()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: kInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        _getAppBarSubtitle(),
                        key: ValueKey<String>(_getAppBarSubtitle()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: kInkSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Notification bell with amber dot ──────────────
              _CircleIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  // TODO: open notifications
                },
                showDot: true,
              ),
              const SizedBox(width: 8),

              // ── Profile avatar with gradient ring ─────────────
              _ProfileAvatar(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AccountScreen(phoneNumber: widget.phoneNumber),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    switch (_selectedNavIndex) {
      case 2:
        return LocalBookingCard(phoneNumber: widget.phoneNumber);
      case 3:
        return AirportBookingCard(phoneNumber: widget.phoneNumber);
      default:
        return BookingCard(
          isOneWay: _isOneWay,
          onToggle: (val) => setState(() => _isOneWay = val),
          phoneNumber: widget.phoneNumber,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Reusable AppBar action widgets
// ─────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kCardBg,
              shape: BoxShape.circle,
              border: Border.all(color: kInputBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: kInk, size: 22),
          ),
          if (showDot)
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kAmberDeep,
                  shape: BoxShape.circle,
                  border: Border.all(color: kCardBg, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: kPrimaryGradient,
          boxShadow: [
            BoxShadow(
              color: kAmber.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kAmberSoft,
            shape: BoxShape.circle,
            border: Border.all(color: kCardBg, width: 2),
          ),
          child: const Icon(Icons.person_rounded, color: kAmberDeep, size: 22),
        ),
      ),
    );
  }
}
