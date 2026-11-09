import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../booking/cab_selection_screen.dart';
import '../../../theme/app_theme.dart';

class LocalBookingCard extends StatefulWidget {
  final String? phoneNumber;
  const LocalBookingCard({super.key, this.phoneNumber});

  @override
  State<LocalBookingCard> createState() => _LocalBookingCardState();
}

class _LocalBookingCardState extends State<LocalBookingCard> {
  final TextEditingController _cityController = TextEditingController();
  double? _cityLat;
  double? _cityLng;
  String? _cityFullAddress;
  int selectedPackageIndex = 1; // 8 hrs / 80 kms by default
  late String startDate;
  late String startTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int minute = now.minute;
    int roundedMinute = ((minute + 14) ~/ 15) * 15;
    final startDt = roundedMinute == 60
        ? DateTime(now.year, now.month, now.day, now.hour + 1, 0)
        : DateTime(now.year, now.month, now.day, now.hour, roundedMinute);

    startDate = DateFormat('dd-MM-yyyy').format(startDt);
    startTime = DateFormat('hh:mm a').format(startDt);
  }

  final List<Map<String, dynamic>> packages = [
    {'time': '5 hrs', 'dist': '50 kms', 'hours': 5, 'kms': 50},
    {'time': '8 hrs', 'dist': '80 kms', 'hours': 8, 'kms': 80},
    {'time': '10 hrs', 'dist': '100 kms', 'hours': 10, 'kms': 100},
    {'time': '12 hrs', 'dist': '120 kms', 'hours': 12, 'kms': 120},
  ];

  void _navigateToCabs() {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter city')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CabSelectionScreen(
              from: _cityFullAddress ?? _cityController.text.trim(),
              to: 'Local (${packages[selectedPackageIndex]['time']})',
              fromLat: _cityLat,
              fromLng: _cityLng,
              date: startDate,
              time: startTime,
              isOneWay: true,
              isRental: true,
              packageHours: packages[selectedPackageIndex]['hours'] as int,
              includedKms: packages[selectedPackageIndex]['kms'] as int,
              phoneNumber: widget.phoneNumber ?? '919243424225',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E7), Color(0xFFFFF0C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kInputBorder, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: kAmber.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: const BoxDecoration(
                      gradient: kPrimaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33FFB300),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.timer_rounded,
                      color: kInk,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LOCAL HOURLY RENTAL PACKAGES',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: kAmberDeep,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.stars_rounded,
                    color: kAmberDeep,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Package Toggle
          Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kInputBg,
              border: Border.all(color: kInputBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(packages.length, (index) {
                bool isSelected = selectedPackageIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedPackageIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? const LinearGradient(
                                  colors: [Color(0xFFFFD54F), kAmber],
                                )
                                : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: kAmber.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                : [],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            packages[index]['time'].toString(),
                            style: GoogleFonts.outfit(
                              color: isSelected ? kInk : kInkSoft,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            packages[index]['dist'].toString(),
                            style: GoogleFonts.outfit(
                              color:
                                  isSelected
                                      ? kInk.withValues(alpha: 0.75)
                                      : kInkSoft.withValues(alpha: 0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // City Input
          CityAutocompleteField(
            label: 'CITY',
            hint: 'Enter Pickup Location',
            icon: Icons.location_on_rounded,
            controller: _cityController,
            onCitySelected: (city) {
              _cityLat = double.tryParse(city['lat']?.toString() ?? '');
              _cityLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
              _cityFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
            },
            onChanged: (_) {
              _cityLat = null;
              _cityLng = null;
              _cityFullAddress = null;
            },
          ),
          const SizedBox(height: 10),
          // Trip Start Date
          _buildTripDateInput(
            context,
            'TRIP START',
            startDate,
            startTime,
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 14),
          // Explore Button
          GestureDetector(
            onTap: _navigateToCabs,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kButtonShadow(),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXPLORE CABS',
                      style: GoogleFonts.outfit(
                        color: kInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: kInk,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Widget _buildTripDateInput(
    BuildContext context,
    String label,
    String date,
    String subText,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder:
              (context) => DateTimePickerDialog(
                label: label,
                initialDate: date,
                initialTime: subText,
              ),
        );
        if (result != null) {
          setState(() {
            startDate = result['displayDate'] ?? result['date'];
            startTime = result['time'];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: kInputBg,
          border: Border.all(color: kInputBorder, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: kAmberDeep,
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: kAmberDeep,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            date,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: kInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: kAmberDeep,
                        size: 15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: kInkSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
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
