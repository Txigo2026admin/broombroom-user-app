import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'date_time_picker.dart';

class PackageBookingDialog extends StatefulWidget {
  final String packageName;

  const PackageBookingDialog({super.key, required this.packageName});

  @override
  State<PackageBookingDialog> createState() => _PackageBookingDialogState();
}

class _PackageBookingDialogState extends State<PackageBookingDialog> {
  String startDate = 'Sun May 03';
  String startTime = '03:00 PM';
  String endDate = 'Wed May 06';
  String endTime = '07:00 PM';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with lines
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.cyan, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        widget.packageName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.cyan, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 24),
                // Input Fields
                _buildField(Icons.location_on_outlined, 'FROM', 'Enter pickup city'),
                const SizedBox(height: 12),
                _buildField(Icons.location_on_outlined, 'NUMBER OF DHAMS', '1 DHAM'),
                const SizedBox(height: 12),
                _buildField(Icons.account_balance, 'ITINERARY', 'Yamunotri'),
                const SizedBox(height: 16),
                // Date Fields Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(context, 'TRIP START', startDate, startTime, (res) {
                        if (res != null) {
                          setState(() {
                            startDate = res['date'];
                            startTime = res['time'];
                          });
                        }
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(context, 'TRIP END', endDate, endTime, (res) {
                        if (res != null) {
                          setState(() {
                            endDate = res['date'];
                            endTime = res['time'];
                          });
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Explore Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'EXPLORE CABS',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Close Button below dialog
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 28),
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
        color: Colors.amber.withOpacity(0.02),
        border: Border.all(color: Colors.amber.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String label, String date, String subText, Function(Map<String, dynamic>?) onResult) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => DateTimePickerDialog(
            label: label,
            initialDate: date,
            initialTime: subText.contains('M') ? subText : '12:00 PM',
          ),
        );
        onResult(result);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.02),
          border: Border.all(color: Colors.amber.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.cyan.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    subText,
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
