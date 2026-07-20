import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../booking/cab_selection_screen.dart';

class LocalBookingCard extends StatefulWidget {
  const LocalBookingCard({super.key});

  @override
  State<LocalBookingCard> createState() => _LocalBookingCardState();
}

class _LocalBookingCardState extends State<LocalBookingCard> {
  final TextEditingController _cityController = TextEditingController();
  int selectedPackageIndex = 1; // 8 hrs / 80 kms by default
  String startDate = 'Mon May 04';
  String startTime = '07:00 AM';

  final List<Map<String, String>> packages = [
    {'time': '4 hrs', 'dist': '40 kms'},
    {'time': '8 hrs', 'dist': '80 kms'},
    {'time': '12 hrs', 'dist': '120 kms'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.cyan, thickness: 1.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'INDIA\'S PREMIER INTERCITY CABS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.shade700,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.cyan, thickness: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          // Package Toggle
          Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: List.generate(packages.length, (index) {
                bool isSelected = selectedPackageIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedPackageIndex = index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            packages[index]['time']!,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            packages[index]['dist']!,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white70 : Colors.grey,
                              fontSize: 12,
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
          const SizedBox(height: 24),
          // City Input
          CityAutocompleteField(
            label: 'CITY',
            hint: 'Enter Pickup Location',
            icon: Icons.location_on_outlined,
            controller: _cityController,
          ),
          const SizedBox(height: 16),
          // Trip Start Date
          _buildTripDateInput(context, 'TRIP START', startDate, startTime, Icons.calendar_today_outlined),
          const SizedBox(height: 24),
          // Explore Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_cityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter city')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CabSelectionScreen(
                      from: _cityController.text,
                      to: 'Local (${packages[selectedPackageIndex]['time']})',
                      date: startDate,
                      time: startTime,
                      isOneWay: true,
                      phoneNumber: '919243424225', // Should probably be passed down
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Widget _buildTripDateInput(BuildContext context, String label, String date, String subText, IconData icon) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => DateTimePickerDialog(
            label: label,
            initialDate: date,
            initialTime: subText,
          ),
        );
        if (result != null) {
          setState(() {
            startDate = result['date'];
            startTime = result['time'];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyan.shade100),
          borderRadius: BorderRadius.circular(8),
          color: Colors.cyan.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan.shade400, size: 24),
            const SizedBox(width: 12),
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    subText,
                    style: GoogleFonts.outfit(color: Colors.cyan.shade400, fontSize: 11),
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
