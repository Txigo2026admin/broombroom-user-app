import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class DateTimePickerDialog extends StatefulWidget {
  final String label;
  final String initialDate;
  final String initialTime;
  final DateTime? minDateTime;

  const DateTimePickerDialog({
    super.key,
    required this.label,
    this.initialDate = '',
    this.initialTime = '',
    this.minDateTime,
  });

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late List<DateTime> rawDates;
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
    _generateDates();
    hours = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    minutes = ['00', '15', '30', '45'];
    periods = ['AM', 'PM'];

    // Match initial date
    selectedDateIndex = 0;
    if (widget.initialDate.isNotEmpty) {
      DateTime? parsed;
      try {
        if (widget.initialDate.contains('-')) {
          parsed = DateFormat('dd-MM-yyyy').parse(widget.initialDate);
        } else if (widget.initialDate.toLowerCase().contains('today')) {
          parsed = DateTime.now();
        } else {
          parsed = DateFormat('EEE MMM dd').parse(widget.initialDate);
        }
      } catch (_) {
        try {
          parsed = DateFormat('E MMM dd').parse(widget.initialDate);
        } catch (_) {}
      }

      if (parsed != null) {
        for (int i = 0; i < rawDates.length; i++) {
          if (rawDates[i].year == parsed.year &&
              rawDates[i].month == parsed.month &&
              rawDates[i].day == parsed.day) {
            selectedDateIndex = i;
            break;
          }
        }
      }
    }

    // Match initial time (or default to minDateTime or current time)
    try {
      String time = widget.initialTime.trim();
      if (time.isEmpty) {
        throw Exception();
      }
      if (time.contains(':') && time.contains(' ')) {
        String h = int.parse(time.split(':')[0].trim()).toString();
        String m = time.split(':')[1].split(' ')[0].trim();
        String p = time.split(' ')[1].trim().toUpperCase();

        selectedHourIndex = hours.indexOf(h);
        if (selectedHourIndex == -1) {
          int hVal = int.tryParse(h) ?? 1;
          if (hVal > 12) hVal -= 12;
          if (hVal == 0) hVal = 12;
          selectedHourIndex = hours.indexOf(hVal.toString());
        }

        int mVal = int.tryParse(m) ?? 0;
        int closestMinIdx = 0;
        int minDiff = 999;
        for (int i = 0; i < minutes.length; i++) {
          int diff = (int.parse(minutes[i]) - mVal).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closestMinIdx = i;
          }
        }
        selectedMinuteIndex = closestMinIdx;
        selectedPeriodIndex = periods.indexOf(p);
      } else {
        throw Exception();
      }
    } catch (_) {
      final fallback = widget.minDateTime ?? DateTime.now();
      int h = fallback.hour;
      String p = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      selectedHourIndex = hours.indexOf(h.toString());
      if (selectedHourIndex == -1) selectedHourIndex = 0;
      selectedPeriodIndex = periods.indexOf(p);
      if (selectedPeriodIndex == -1) selectedPeriodIndex = 0;

      int mVal = fallback.minute;
      int closestMinIdx = 0;
      int minDiff = 999;
      for (int i = 0; i < minutes.length; i++) {
        int diff = (int.parse(minutes[i]) - mVal).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestMinIdx = i;
        }
      }
      selectedMinuteIndex = closestMinIdx;
    }

    if (selectedHourIndex == -1) selectedHourIndex = 0;
    if (selectedMinuteIndex == -1) selectedMinuteIndex = 0;
    if (selectedPeriodIndex == -1) selectedPeriodIndex = 0;
  }

  void _generateDates() {
    rawDates = [];
    dates = [];
    final baseDate = widget.minDateTime ?? DateTime.now();
    DateTime start = DateTime(baseDate.year, baseDate.month, baseDate.day);
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 90; i++) {
      DateTime d = start.add(Duration(days: i));
      rawDates.add(d);
      if (d.year == todayStart.year &&
          d.month == todayStart.month &&
          d.day == todayStart.day) {
        dates.add('Today');
      } else {
        dates.add(DateFormat('EEE MMM dd').format(d));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentSelectedDate = rawDates[selectedDateIndex];
    String formattedSummaryDate = DateFormat('EEE, dd MMM').format(currentSelectedDate);
    String formattedHour = hours[selectedHourIndex].padLeft(2, '0');
    String formattedMinute = minutes[selectedMinuteIndex];
    String currentPeriod = periods[selectedPeriodIndex];
    String formattedTime = '$formattedHour:$formattedMinute $currentPeriod';

    return Dialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: kInputBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.label == 'TRIP START' ? 'Trip Start' : (widget.label == 'TRIP END' ? 'Trip End' : widget.label)} Date And Time',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kAmberSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: kInputBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: kInk,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: kInputBorder.withValues(alpha: 0.6), height: 1),
            const SizedBox(height: 16),

            // Wheel Scroll View
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center selection highlight frame
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: kAmberSoft.withValues(alpha: 0.5),
                      border: Border.all(
                        color: kAmberDeep,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      // Dates Column
                      _buildPickerColumn(
                        items: dates,
                        selectedIndex: selectedDateIndex,
                        onSelected: (i) => selectedDateIndex = i,
                        flex: 5,
                      ),
                      // Hours Column
                      _buildPickerColumn(
                        items: hours,
                        selectedIndex: selectedHourIndex,
                        onSelected: (i) => selectedHourIndex = i,
                        flex: 2,
                      ),
                      // Separator
                      Text(
                        ':',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: kAmberDeep,
                        ),
                      ),
                      // Minutes Column
                      _buildPickerColumn(
                        items: minutes,
                        selectedIndex: selectedMinuteIndex,
                        onSelected: (i) => selectedMinuteIndex = i,
                        flex: 2,
                      ),
                      // Period Column (AM/PM)
                      _buildPickerColumn(
                        items: periods,
                        selectedIndex: selectedPeriodIndex,
                        onSelected: (i) => selectedPeriodIndex = i,
                        flex: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kInputBg,
                border: Border.all(
                  color: kInputBorder,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: kAmberDeep,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedSummaryDate,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedTime,
                    style: GoogleFonts.outfit(
                      color: kInkSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Confirm Button
            GestureDetector(
              onTap: () {
                DateTime selectedDate = rawDates[selectedDateIndex];
                int h = int.parse(hours[selectedHourIndex]);
                int m = int.parse(minutes[selectedMinuteIndex]);
                String p = periods[selectedPeriodIndex];
                if (p == 'PM' && h < 12) h += 12;
                if (p == 'AM' && h == 12) h = 0;
                DateTime fullDt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, m);

                String finalTime = formattedTime;
                DateTime finalDate = selectedDate;

                if (widget.minDateTime != null && fullDt.isBefore(widget.minDateTime!)) {
                  fullDt = widget.minDateTime!;
                  finalDate = DateTime(fullDt.year, fullDt.month, fullDt.day);
                  int clampedH = fullDt.hour;
                  String clampedP = clampedH >= 12 ? 'PM' : 'AM';
                  if (clampedH > 12) clampedH -= 12;
                  if (clampedH == 0) clampedH = 12;
                  String clampedHourStr = clampedH.toString().padLeft(2, '0');

                  int clampedMVal = fullDt.minute;
                  int clampedMinIdx = 0;
                  int diffMin = 999;
                  for (int i = 0; i < minutes.length; i++) {
                    int diff = (int.parse(minutes[i]) - clampedMVal).abs();
                    if (diff < diffMin) {
                      diffMin = diff;
                      clampedMinIdx = i;
                    }
                  }
                  String clampedMinStr = minutes[clampedMinIdx];
                  finalTime = '$clampedHourStr:$clampedMinStr $clampedP';
                }

                Navigator.pop(context, {
                  'date': DateFormat('dd-MM-yyyy').format(finalDate),
                  'displayDate': DateFormat('dd-MM-yyyy').format(finalDate),
                  'summaryDate': DateFormat('EEE, dd MMM').format(finalDate),
                  'dayName': DateFormat('EEEE').format(finalDate),
                  'time': finalTime,
                  'rawDate': finalDate,
                  'fullDateTime': fullDt,
                });
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: kButtonShadow(),
                ),
                child: Center(
                  child: Text(
                    'CONFIRM',
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 44,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: selectedIndex),
        onSelectedItemChanged: (index) {
          setState(() {
            onSelected(index);
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            final bool isSelected = index == selectedIndex;
            return Center(
              child: Text(
                items[index],
                style: GoogleFonts.outfit(
                  fontSize: isSelected ? 15.5 : 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? kAmberDeep
                      : kInk.withValues(alpha: 0.6),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
