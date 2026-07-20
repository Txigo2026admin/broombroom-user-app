import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../booking/cab_selection_screen.dart';

class AirportBookingCard extends StatefulWidget {
  const AirportBookingCard({super.key});

  @override
  State<AirportBookingCard> createState() => _AirportBookingCardState();
}

class _AirportBookingCardState extends State<AirportBookingCard> {
  final TextEditingController _airportController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool isPickup = true;
  String startDate = 'Sun May 03';
  String startTime = '05:00 PM';

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
                  'RELIABLE AIRPORT PICKUPS & DROPS',
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
          // Toggle
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton(true, 'PICKUP', 'PICKUP FROM AIRPORT'),
                _buildToggleButton(false, 'DROP', 'DROP TO AIRPORT'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Airport Input
          CityAutocompleteField(
            label: 'AIRPORT',
            hint: 'Airport/city name - e.g. Mumbai',
            icon: Icons.location_on_outlined,
            controller: _airportController,
          ),
          const SizedBox(height: 12),
          // Address Input
          CityAutocompleteField(
            label: isPickup ? 'DROP ADDRESS' : 'PICKUP ADDRESS',
            hint: 'Enter your address/locality',
            icon: Icons.location_on_outlined,
            controller: _addressController,
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
                if (_airportController.text.isEmpty || _addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both airport and address')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CabSelectionScreen(
                      from: isPickup ? _airportController.text : _addressController.text,
                      to: isPickup ? _addressController.text : _airportController.text,
                      date: startDate,
                      time: startTime,
                      isOneWay: true,
                      phoneNumber: '919243424225',
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

  Widget _buildToggleButton(bool value, String title, String subText) {
    bool isSelected = isPickup == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPickup = value),
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
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subText,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white70 : Colors.grey,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _airportController.dispose();
    _addressController.dispose();
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
