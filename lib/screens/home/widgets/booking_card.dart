import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../../data/cities.dart';
import '../../booking/cab_selection_screen.dart';

class BookingCard extends StatefulWidget {
  final bool isOneWay;
  final Function(bool) onToggle;
  final String phoneNumber;

  const BookingCard({
    super.key,
    required this.isOneWay,
    required this.onToggle,
    required this.phoneNumber,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  String startDate = DateFormat('E MMM dd').format(DateTime.now());
  String startTime = DateFormat('hh:mm a').format(DateTime.now());
  String endDate = DateFormat('E MMM dd').format(DateTime.now().add(const Duration(days: 1)));
  String endTime = DateFormat('hh:mm a').format(DateTime.now());

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

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
          Text(
            'INDIA\'S PREMIER INTERCITY CABS',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggle(),
          const SizedBox(height: 24),
          _buildLocations(),
          const SizedBox(height: 16),
          _buildStopsSection(),
          const SizedBox(height: 16),
          _buildDates(context),
          const SizedBox(height: 24),
          _buildExploreButton(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(true, 'ONE WAY', 'Drop-off only'),
          _buildToggleButton(false, 'ROUND TRIP', 'Return with same cab'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(bool value, String title, String subText) {
    bool isSelected = widget.isOneWay == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onToggle(value),
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
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocations() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          children: [
            CityAutocompleteField(
              label: 'FROM',
              hint: 'Enter the City',
              icon: Icons.location_on_outlined,
              controller: _fromController,
            ),
            const SizedBox(height: 12),
            CityAutocompleteField(
              label: 'TO',
              hint: 'Enter the City',
              icon: Icons.location_on_outlined,
              controller: _toController,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 20),
          child: GestureDetector(
            onTap: () {
              String temp = _fromController.text;
              _fromController.text = _toController.text;
              _toController.text = temp;
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Icon(Icons.swap_vert, color: Colors.amber.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopsSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+ ADD STOPS',
            style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'NEW',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDates(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTripDateInput(
            context,
            'TRIP START',
            startDate,
            startTime,
            Icons.calendar_today_outlined,
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
        if (!widget.isOneWay) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildTripDateInput(
              context,
              'TRIP END',
              endDate,
              endTime,
              Icons.calendar_today_outlined,
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
      ],
    );
  }

  Widget _buildTripDateInput(
    BuildContext context,
    String label,
    String date,
    String subText,
    IconData icon,
    Function(Map<String, dynamic>?) onResult,
  ) {
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
          border: Border.all(color: Colors.amber.shade100),
          borderRadius: BorderRadius.circular(8),
          color: Colors.amber.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber.shade400, size: 20),
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

  Widget _buildExploreButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (_fromController.text.isEmpty || _toController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter both pickup and destination cities')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CabSelectionScreen(
                from: _fromController.text,
                to: _toController.text,
                date: startDate,
                time: startTime,
                isOneWay: widget.isOneWay,
                phoneNumber: widget.phoneNumber,
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
    );
  }
}
