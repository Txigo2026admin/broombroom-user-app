import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../data/services/booking_service.dart';

class PackageBookingDialog extends StatefulWidget {
  final String packageName;
  final void Function({
    required String fromCity,
    required String toCity,
    required String startDate,
    required String startTime,
    String? endDate,
    String? endTime,
    double? fromLat,
    double? fromLng,
  })? onExplore;

  const PackageBookingDialog({
    super.key,
    required this.packageName,
    this.onExplore,
  });

  @override
  State<PackageBookingDialog> createState() => _PackageBookingDialogState();
}

class _PackageBookingDialogState extends State<PackageBookingDialog> {
  final TextEditingController _fromController = TextEditingController();
  double? _fromLat;
  double? _fromLng;

  late String startDate;
  late String startTime;
  late String endDate;
  late String endTime;

  late String selectedDham;
  late String selectedItinerary;

  final List<String> dhamOptions = ['1 DHAM', '2 DHAMS', '4 DHAMS'];

  static DateTime _getInitialStartTime() {
    final now = DateTime.now();
    // Outstation package tour: 1 hour after current time
    final minTime = now.add(const Duration(hours: 1));
    int remainder = minTime.minute % 15;
    int minutesToAdd = remainder == 0 ? 0 : (15 - remainder);
    final rounded = minTime.add(Duration(minutes: minutesToAdd));
    return DateTime(
      rounded.year,
      rounded.month,
      rounded.day,
      rounded.hour,
      rounded.minute,
    );
  }

  @override
  void initState() {
    super.initState();
    final isChardham =
        widget.packageName.toLowerCase().contains('chardham') ||
        widget.packageName.toLowerCase().contains('dham');

    selectedDham = isChardham ? '1 DHAM' : 'Tour Package';
    selectedItinerary = isChardham ? 'Yamunotri' : 'Goa Beach Circuit';
    _fromController.text = isChardham ? 'Haridwar' : 'Kolkata';

    final startDt = _getInitialStartTime();
    final durationDays = isChardham ? 3 : 4;
    final endDt = startDt.add(Duration(days: durationDays));

    startDate = DateFormat('dd-MM-yyyy').format(startDt);
    startTime = DateFormat('hh:mm a').format(startDt);
    endDate = DateFormat('dd-MM-yyyy').format(endDt);
    endTime = DateFormat('hh:mm a').format(endDt);
  }

  @override
  void dispose() {
    _fromController.dispose();
    super.dispose();
  }

  void _onDhamChanged(String dham) {
    setState(() {
      selectedDham = dham;
      int days = 3;
      if (dham == '1 DHAM') {
        selectedItinerary = 'Yamunotri';
        days = 3;
      } else if (dham == '2 DHAMS') {
        selectedItinerary = 'Kedarnath - Badrinath';
        days = 5;
      } else if (dham == '4 DHAMS') {
        selectedItinerary = 'Yamunotri - Gangotri - Kedarnath - Badrinath';
        days = 10;
      }

      try {
        final parts = startDate.split('-');
        final startDt = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        final endDt = startDt.add(Duration(days: days));
        endDate = DateFormat('dd-MM-yyyy').format(endDt);
      } catch (_) {}
    });
  }

  void _showDhamPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Number of Dhams',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 14),
              ...dhamOptions.map((opt) {
                final isSelected = opt == selectedDham;
                return ListTile(
                  title: Text(
                    opt,
                    style: GoogleFonts.outfit(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? kAmberDeep : kInk,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check_circle, color: kAmberDeep)
                          : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onDhamChanged(opt);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showItineraryPicker() {
    List<String> itineraries;
    if (selectedDham == '1 DHAM') {
      itineraries = ['Yamunotri', 'Gangotri', 'Kedarnath', 'Badrinath'];
    } else if (selectedDham == '2 DHAMS') {
      itineraries = ['Kedarnath - Badrinath', 'Yamunotri - Gangotri'];
    } else if (selectedDham == '4 DHAMS') {
      itineraries = [
        'Yamunotri - Gangotri - Kedarnath - Badrinath (Complete Yatra)',
      ];
    } else {
      itineraries = ['Goa Beach Circuit', 'Puri - Konark Coastal', 'Gokarna Beach Trail'];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Itinerary',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 14),
              ...itineraries.map((itin) {
                final isSelected = itin == selectedItinerary;
                return ListTile(
                  title: Text(
                    itin,
                    style: GoogleFonts.outfit(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? kAmberDeep : kInk,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check_circle, color: kAmberDeep)
                          : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => selectedItinerary = itin);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCityDialog() {
    final popularCities = ['Haridwar', 'Rishikesh', 'Dehradun', 'Delhi', 'Kolkata', 'Mumbai'];
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: _fromController.text);
        return AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Pickup City',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: kInk),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.outfit(color: kInk, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter pickup city',
                  hintStyle: GoogleFonts.outfit(color: kInkSoft),
                  prefixIcon: const Icon(Icons.trip_origin_rounded, color: kAmberDeep),
                  filled: true,
                  fillColor: kInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kInputBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Popular Pickup Cities:',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kInkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: popularCities.map((c) {
                  return InkWell(
                    onTap: () {
                      ctrl.text = c;
                      _fromController.text = c;
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kAmberSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: kInkSoft, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAmberDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  _fromController.text = ctrl.text.trim();
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(
                'Done',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleExploreCabs() {
    final pickup =
        _fromController.text.trim().isNotEmpty
            ? _fromController.text.trim()
            : 'Haridwar';
    final destination = '$selectedItinerary ($selectedDham)';

    // 1. Record Search Lead in backend immediately
    BookingService.recordSearchLead(
      pickupAddress: pickup,
      dropAddress: destination,
      fromCity: pickup,
      toCity: destination,
      serviceType: 'outstation-roundtrip',
      wayType: 'Round Trip',
      pickupDate: startDate,
      pickupTime: startTime,
      returnDate: endDate,
      returnTime: endTime,
      rentalPackage: '${widget.packageName} - $selectedDham',
    );

    // 2. Dismiss dialog and redirect to search bar
    Navigator.pop(context);

    // 3. Callback to redirect home screen to the Search Bar with round trip prefilled
    widget.onExplore?.call(
      fromCity: pickup,
      toCity: destination,
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
      fromLat: _fromLat,
      fromLng: _fromLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kInputBorder),
              boxShadow: kCardShadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with lines
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: kInputBorder, thickness: 1.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        widget.packageName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kAmberDeep,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: kInputBorder, thickness: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // FROM field (interactive)
                _buildClickableField(
                  icon: Icons.trip_origin_rounded,
                  label: 'FROM',
                  value:
                      _fromController.text.trim().isNotEmpty
                          ? _fromController.text.trim()
                          : 'Enter pickup city',
                  onTap: _showCityDialog,
                ),
                const SizedBox(height: 12),

                // NUMBER OF DHAMS field
                _buildClickableField(
                  icon: Icons.navigation_rounded,
                  label: 'NUMBER OF DHAMS',
                  value: selectedDham,
                  onTap: _showDhamPicker,
                  trailing: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: kInkSoft,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),

                // ITINERARY field
                _buildClickableField(
                  icon: Icons.map_rounded,
                  label: 'ITINERARY',
                  value: selectedItinerary,
                  onTap: _showItineraryPicker,
                  trailing: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: kInkSoft,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 14),

                // Date Fields Row
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context,
                          'TRIP START',
                          startDate,
                          startTime,
                          (res) {
                            if (res != null) {
                              setState(() {
                                startDate = res['displayDate'] ?? res['date'];
                                startTime = res['time'];
                              });
                            }
                          },
                          minDateTime: _getInitialStartTime(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          context,
                          'TRIP END',
                          endDate,
                          endTime,
                          (res) {
                            if (res != null) {
                              setState(() {
                                endDate = res['displayDate'] ?? res['date'];
                                endTime = res['time'];
                              });
                            }
                          },
                          minDateTime: _getInitialStartTime().add(
                            const Duration(hours: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Explore Button: redirects to search bar
                GestureDetector(
                  onTap: _handleExploreCabs,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: kButtonShadow(),
                    ),
                    child: Center(
                      child: Text(
                        'EXPLORE CABS',
                        style: GoogleFonts.outfit(
                          color: kInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Close Button below dialog
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: kInputBorder),
                boxShadow: [
                  BoxShadow(
                    color: kAmber.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: kInk, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: kInputBg,
          border: Border.all(color: kInputBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: kAmberDeep, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: kInkSoft,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    String date,
    String subText,
    Function(Map<String, dynamic>?) onResult, {
    DateTime? minDateTime,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder:
              (context) => DateTimePickerDialog(
                label: label,
                initialDate: date,
                initialTime: subText.contains('M') ? subText : '12:00 PM',
                minDateTime: minDateTime ?? _getInitialStartTime(),
              ),
        );
        onResult(result);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kInputBg,
          border: Border.all(color: kInputBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: kAmberDeep,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: kInkSoft,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      date,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kInk,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subText,
                      style: GoogleFonts.outfit(color: kInkSoft, fontSize: 11),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kInkSoft, size: 16),
          ],
        ),
      ),
    );
  }
}
