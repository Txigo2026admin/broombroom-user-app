import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DateTimePickerDialog extends StatefulWidget {
  final String label;
  final String initialDate;
  final String initialTime;

  const DateTimePickerDialog({
    super.key,
    required this.label,
    this.initialDate = '',
    this.initialTime = '03:45 PM',
  });

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late List<String> dates;
  late List<String> hours;
  late List<String> minutes;
  late List<String> periods;

  late int selectedDateIndex;
  late int selectedHourIndex;
  late int selectedMinuteIndex;
  late int selectedPeriodIndex;

  @override
  void initState() {
    super.initState();
    dates = _generateDates();
    hours = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    minutes = ['00', '15', '30', '45'];
    periods = ['AM', 'PM'];

    // Initialize indices based on initial values if provided
    selectedDateIndex = widget.initialDate.isNotEmpty ? dates.indexOf(widget.initialDate) : 0;
    if (selectedDateIndex == -1) selectedDateIndex = 0;

    // Safe Parse initial time "HH:MM AM/PM"
    try {
      String time = widget.initialTime;
      if (time.contains(':') && time.contains(' ')) {
        String h = time.split(':')[0];
        String m = time.split(':')[1].split(' ')[0];
        String p = time.split(' ')[1];

        selectedHourIndex = hours.indexOf(h);
        selectedMinuteIndex = minutes.indexOf(m);
        selectedPeriodIndex = periods.indexOf(p);
      } else {
        throw Exception("Invalid format");
      }
    } catch (e) {
      selectedHourIndex = 2; // Default 3
      selectedMinuteIndex = 3; // Default 45
      selectedPeriodIndex = 1; // Default PM
    }

    if (selectedHourIndex == -1) selectedHourIndex = 2;
    if (selectedMinuteIndex == -1) selectedMinuteIndex = 3;
    if (selectedPeriodIndex == -1) selectedPeriodIndex = 1;
  }

  List<String> _generateDates() {
    List<String> d = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 90; i++) {
      DateTime date = now.add(Duration(days: i));
      d.add(DateFormat('EEE MMM dd').format(date));
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.label} Date And Time',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.05),
                              border: Border.all(color: Colors.amber.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPickerColumn(dates, selectedDateIndex, (i) => setState(() => selectedDateIndex = i)),
                              _buildPickerColumn(hours, selectedHourIndex, (i) => setState(() => selectedHourIndex = i)),
                              const Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                              _buildPickerColumn(minutes, selectedMinuteIndex, (i) => setState(() => selectedMinuteIndex = i)),
                              _buildPickerColumn(periods, selectedPeriodIndex, (i) => setState(() => selectedPeriodIndex = i)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.02),
                        border: Border.all(color: Colors.amber.shade100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label.toUpperCase(),
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dates[selectedDateIndex],
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '${hours[selectedHourIndex]}:${minutes[selectedMinuteIndex]} ${periods[selectedPeriodIndex]}',
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          String resultDate = dates[selectedDateIndex];
                          String resultTime = '${hours[selectedHourIndex]}:${minutes[selectedMinuteIndex]} ${periods[selectedPeriodIndex]}';
                          Navigator.pop(context, {'date': resultDate, 'time': resultTime});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'CONFIRM',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn(List<String> items, int selectedIndex, Function(int) onSelected) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: selectedIndex),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            bool isSelected = index == selectedIndex;
            return Center(
              child: Text(
                items[index],
                style: GoogleFonts.outfit(
                  fontSize: isSelected ? 16 : 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.amber : Colors.grey.shade400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
