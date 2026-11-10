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
  late DateTime effectiveMinDateTime;
  late List<DateTime> rawDates;
  late List<String> dates;
  late List<String> hours;
  late List<String> minutes;
  late List<String> periods;

  late int selectedDateIndex;
  late int selectedHourIndex;
  late int selectedMinuteIndex;
  late int selectedPeriodIndex;

  static DateTime calculateDefaultMinTime() {
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

  void _applyDateTimeToIndices(DateTime dt) {
    int h = dt.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    selectedHourIndex = hours.indexOf(h.toString());
    if (selectedHourIndex == -1) selectedHourIndex = 0;
    selectedPeriodIndex = periods.indexOf(p);
    if (selectedPeriodIndex == -1) selectedPeriodIndex = 0;

    int mVal = dt.minute;
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

  @override
  void initState() {
    super.initState();
    effectiveMinDateTime = widget.minDateTime ?? calculateDefaultMinTime();
    _generateDates();
    hours = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    minutes = ['00', '15', '30', '45'];
    periods = ['AM', 'PM'];

    // Match initial date
    selectedDateIndex = 0;
    DateTime? parsedDate;
    if (widget.initialDate.isNotEmpty) {
      try {
        if (widget.initialDate.contains('-')) {
          parsedDate = DateFormat('dd-MM-yyyy').parse(widget.initialDate);
        } else if (widget.initialDate.toLowerCase().contains('today')) {
          parsedDate = DateTime.now();
        } else {
          parsedDate = DateFormat('EEE MMM dd').parse(widget.initialDate);
        }
      } catch (_) {
        try {
          parsedDate = DateFormat('E MMM dd').parse(widget.initialDate);
        } catch (_) {}
      }

      if (parsedDate != null) {
        for (int i = 0; i < rawDates.length; i++) {
          if (rawDates[i].year == parsedDate.year &&
              rawDates[i].month == parsedDate.month &&
              rawDates[i].day == parsedDate.day) {
            selectedDateIndex = i;
            break;
          }
        }
      }
    }

    // Match initial time
    bool initialTimeSet = false;
    try {
      String time = widget.initialTime.trim();
      if (time.isNotEmpty && time.contains(':') && time.contains(' ')) {
        String h = int.parse(time.split(':')[0].trim()).toString();
        String m = time.split(':')[1].split(' ')[0].trim();
        String p = time.split(' ')[1].trim().toUpperCase();

        int parsedH = int.parse(h);
        int parsedM = int.parse(m);
        int full24H = parsedH;
        if (p == 'PM' && full24H < 12) full24H += 12;
        if (p == 'AM' && full24H == 12) full24H = 0;

        DateTime targetDate = rawDates[selectedDateIndex];
        DateTime fullDt = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          full24H,
          parsedM,
        );

        if (!fullDt.isBefore(effectiveMinDateTime)) {
          selectedHourIndex = hours.indexOf(
            parsedH > 12
                ? (parsedH - 12).toString()
                : (parsedH == 0 ? '12' : parsedH.toString()),
          );
          if (selectedHourIndex == -1) selectedHourIndex = 0;

          int closestMinIdx = 0;
          int minDiff = 999;
          for (int i = 0; i < minutes.length; i++) {
            int diff = (int.parse(minutes[i]) - parsedM).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closestMinIdx = i;
            }
          }
          selectedMinuteIndex = closestMinIdx;
          selectedPeriodIndex = periods.indexOf(p);
          if (selectedPeriodIndex == -1) selectedPeriodIndex = 0;
          initialTimeSet = true;
        }
      }
    } catch (_) {}

    if (!initialTimeSet) {
      // Default directly to effectiveMinDateTime (always at least 15 mins after current time)
      _applyDateTimeToIndices(effectiveMinDateTime);
    }

    if (selectedHourIndex == -1) selectedHourIndex = 0;
    if (selectedMinuteIndex == -1) selectedMinuteIndex = 0;
    if (selectedPeriodIndex == -1) selectedPeriodIndex = 0;
  }

  void _generateDates() {
    rawDates = [];
    dates = [];
    final baseDate = effectiveMinDateTime;
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
    String formattedSummaryDate =
        DateFormat('EEE, dd MMM').format(currentSelectedDate);
    String formattedHour = hours[selectedHourIndex].padLeft(2, '0');
    String formattedMinute = minutes[selectedMinuteIndex];
    String currentPeriod = periods[selectedPeriodIndex];
    String formattedTime = '$formattedHour:$formattedMinute $currentPeriod';

    int curH = int.parse(hours[selectedHourIndex]);
    int curM = int.parse(minutes[selectedMinuteIndex]);
    if (currentPeriod == 'PM' && curH < 12) curH += 12;
    if (currentPeriod == 'AM' && curH == 12) curH = 0;
    DateTime currentFullDt = DateTime(
      currentSelectedDate.year,
      currentSelectedDate.month,
      currentSelectedDate.day,
      curH,
      curM,
    );
    bool isPast = currentFullDt.isBefore(effectiveMinDateTime);

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
                  color:
                      isPast
                          ? Colors.redAccent.withValues(alpha: 0.8)
                          : kInputBorder,
                  width: isPast ? 1.5 : 1.2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PAST TIME',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
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
                      color: isPast ? Colors.redAccent : kInkSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isPast) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Must be at least 15 min after current time (Min: ${DateFormat('hh:mm a').format(effectiveMinDateTime)})',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                DateTime fullDt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  h,
                  m,
                );

                if (fullDt.isBefore(effectiveMinDateTime)) {
                  // Past or too early time selected: clamp to minimum allowed future time
                  fullDt = effectiveMinDateTime;
                  final clampedDate = DateTime(
                    fullDt.year,
                    fullDt.month,
                    fullDt.day,
                  );
                  final clampedTime = DateFormat('hh:mm a').format(fullDt);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Trip start cannot be in the past. Calculated earliest time: $clampedTime.',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: Colors.black87,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  Navigator.pop(context, {
                    'date': DateFormat('dd-MM-yyyy').format(clampedDate),
                    'displayDate': DateFormat(
                      'dd-MM-yyyy',
                    ).format(clampedDate),
                    'summaryDate': DateFormat(
                      'EEE, dd MMM',
                    ).format(clampedDate),
                    'dayName': DateFormat('EEEE').format(clampedDate),
                    'time': clampedTime,
                    'rawDate': clampedDate,
                    'fullDateTime': fullDt,
                  });
                  return;
                }

                Navigator.pop(context, {
                  'date': DateFormat('dd-MM-yyyy').format(selectedDate),
                  'displayDate': DateFormat(
                    'dd-MM-yyyy',
                  ).format(selectedDate),
                  'summaryDate': DateFormat(
                    'EEE, dd MMM',
                  ).format(selectedDate),
                  'dayName': DateFormat('EEEE').format(selectedDate),
                  'time': formattedTime,
                  'rawDate': selectedDate,
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
