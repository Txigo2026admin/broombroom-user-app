import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../theme/app_theme.dart';

class PackageBookingDialog extends StatefulWidget {
  final String packageName;

  const PackageBookingDialog({super.key, required this.packageName});

  @override
  State<PackageBookingDialog> createState() => _PackageBookingDialogState();
}

class _PackageBookingDialogState extends State<PackageBookingDialog> {
  late String startDate;
  late String startTime;
  late String endDate;
  late String endTime;

  static DateTime _getInitialStartTime() {
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 15));
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
    final startDt = _getInitialStartTime();
    final endDt = startDt.add(const Duration(days: 3));

    startDate = DateFormat('dd-MM-yyyy').format(startDt);
    startTime = DateFormat('hh:mm a').format(startDt);
    endDate = DateFormat('dd-MM-yyyy').format(endDt);
    endTime = DateFormat('hh:mm a').format(endDt);
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
                // Input Fields
                _buildField(
                  Icons.trip_origin_rounded,
                  'FROM',
                  'Enter pickup city',
                ),
                const SizedBox(height: 12),
                _buildField(
                  Icons.navigation_rounded,
                  'NUMBER OF DHAMS',
                  '1 DHAM',
                ),
                const SizedBox(height: 12),
                _buildField(Icons.map_rounded, 'ITINERARY', 'Yamunotri'),
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
                                startDate = res['date'];
                                startTime = res['time'];
                              });
                            }
                          },
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
                                endDate = res['date'];
                                endTime = res['time'];
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Explore Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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

  Widget _buildField(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kInputBg,
        border: Border.all(color: kInputBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: kAmberDeep, size: 22),
          const SizedBox(width: 12),
          Column(
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
              ),
            ],
          ),
        ],
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
