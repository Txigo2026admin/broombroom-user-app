import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../booking/cab_selection_screen.dart';
import '../../../theme/app_theme.dart';

class BookingCard extends StatefulWidget {
  final bool isOneWay;
  final Function(bool) onToggle;
  final String phoneNumber;
  final String? initialFrom;
  final String? initialTo;
  final double? initialFromLat;
  final double? initialFromLng;
  final double? initialToLat;
  final double? initialToLng;
  final String? initialStartDate;
  final String? initialStartTime;

  const BookingCard({
    super.key,
    required this.isOneWay,
    required this.onToggle,
    required this.phoneNumber,
    this.initialFrom,
    this.initialTo,
    this.initialFromLat,
    this.initialFromLng,
    this.initialToLat,
    this.initialToLng,
    this.initialStartDate,
    this.initialStartTime,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  double? _fromLat;
  double? _fromLng;
  double? _toLat;
  double? _toLng;
  String? _fromFullAddress;
  String? _toFullAddress;
  late String startDate;
  late String startTime;
  late String endDate;
  late String endTime;

  @override
  void initState() {
    super.initState();
    final startDt = _getInitialStartTime();
    final endDt = startDt.add(const Duration(hours: 3));

    startDate =
        widget.initialStartDate ?? DateFormat('dd-MM-yyyy').format(startDt);
    startTime =
        widget.initialStartTime ?? DateFormat('hh:mm a').format(startDt);

    endDate = DateFormat('dd-MM-yyyy').format(endDt);
    endTime = DateFormat('hh:mm a').format(endDt);

    if (widget.initialFrom != null && widget.initialFrom!.isNotEmpty) {
      _fromController.text = widget.initialFrom!;
      _fromFullAddress = widget.initialFrom;
      _fromLat = widget.initialFromLat;
      _fromLng = widget.initialFromLng;
    }
    if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
      _toController.text = widget.initialTo!;
      _toFullAddress = widget.initialTo;
      _toLat = widget.initialToLat;
      _toLng = widget.initialToLng;
    }
  }

  @override
  void didUpdateWidget(BookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFrom != null &&
        widget.initialFrom != oldWidget.initialFrom) {
      _fromController.text = widget.initialFrom!;
      _fromFullAddress = widget.initialFrom;
      _fromLat = widget.initialFromLat;
      _fromLng = widget.initialFromLng;
    }
    if (widget.initialTo != null && widget.initialTo != oldWidget.initialTo) {
      _toController.text = widget.initialTo!;
      _toFullAddress = widget.initialTo;
      _toLat = widget.initialToLat;
      _toLng = widget.initialToLng;
    }
    if (widget.initialStartDate != null &&
        widget.initialStartDate != oldWidget.initialStartDate) {
      startDate = widget.initialStartDate!;
    }
    if (widget.initialStartTime != null &&
        widget.initialStartTime != oldWidget.initialStartTime) {
      startTime = widget.initialStartTime!;
    }
  }

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

  static DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('-');
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      final timeParts = timeStr.trim().split(' ');
      final hm = timeParts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final period = timeParts.length > 1 ? timeParts[1].toUpperCase() : 'AM';

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildToggle(),
          const SizedBox(height: 10),
          _buildLocations(),
          const SizedBox(height: 8),
          _buildStopsSection(),
          const SizedBox(height: 8),
          _buildDates(context),
          const SizedBox(height: 12),
          _buildExploreButton(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Center(
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
                Icons.local_taxi_rounded,
                color: kInk,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "INDIA'S PREMIER INTERCITY CABS",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: kAmberDeep,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified_rounded, color: kAmberDeep, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: kInputBg,
        border: Border.all(color: kInputBorder),
        borderRadius: BorderRadius.circular(14),
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
    final bool isSelected = widget.isOneWay == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onToggle(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(colors: [Color(0xFFFFD54F), kAmber])
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? kInk : kInkSoft,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color:
                      isSelected
                          ? kInk.withValues(alpha: 0.7)
                          : kInkSoft.withValues(alpha: 0.7),
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCabs() {
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and destination cities'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CabSelectionScreen(
              from: _fromFullAddress ?? _fromController.text.trim(),
              to: _toFullAddress ?? _toController.text.trim(),
              fromLat: _fromLat,
              fromLng: _fromLng,
              toLat: _toLat,
              toLng: _toLng,
              date: startDate,
              time: startTime,
              returnDate: !widget.isOneWay ? endDate : null,
              returnTime: !widget.isOneWay ? endTime : null,
              isOneWay: widget.isOneWay,
              phoneNumber: widget.phoneNumber,
            ),
      ),
    );
  }

  // ── Locations ─────────────────────────────────────────────────────
  Widget _buildLocations() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          children: [
            CityAutocompleteField(
              label: 'FROM',
              hint: 'Enter Pickup City / Area / Pincode',
              icon: Icons.trip_origin_rounded,
              controller: _fromController,
              focusNode: _fromFocusNode,
              onCitySelected: (city) {
                _fromLat = double.tryParse(city['lat']?.toString() ?? '');
                _fromLng = double.tryParse(
                  (city['lon'] ?? city['lng'])?.toString() ?? '',
                );
                _fromFullAddress =
                    (city['display_name'] ?? city['displayName'])?.toString();
                if (_toController.text.trim().isEmpty) {
                  _toFocusNode.requestFocus();
                }
              },
              onChanged: (_) {
                _fromLat = null;
                _fromLng = null;
                _fromFullAddress = null;
              },
            ),
            const SizedBox(height: 10),
            CityAutocompleteField(
              label: 'TO',
              hint: 'Enter Destination City / Area / Pincode',
              icon: Icons.location_on_rounded,
              controller: _toController,
              focusNode: _toFocusNode,
              onCitySelected: (city) {
                _toLat = double.tryParse(city['lat']?.toString() ?? '');
                _toLng = double.tryParse(
                  (city['lon'] ?? city['lng'])?.toString() ?? '',
                );
                _toFullAddress =
                    (city['display_name'] ?? city['displayName'])?.toString();
                if (_fromController.text.trim().isEmpty) {
                  _fromFocusNode.requestFocus();
                }
              },
              onChanged: (_) {
                _toLat = null;
                _toLng = null;
                _toFullAddress = null;
              },
            ),
          ],
        ),
        Positioned(
          right: 12,
          child: GestureDetector(
            onTap: () {
              final String temp = _fromController.text;
              _fromController.text = _toController.text;
              _toController.text = temp;
              final tempLat = _fromLat;
              final tempLng = _fromLng;
              final tempFull = _fromFullAddress;
              _fromLat = _toLat;
              _fromLng = _toLng;
              _fromFullAddress = _toFullAddress;
              _toLat = tempLat;
              _toLng = tempLng;
              _toFullAddress = tempFull;
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: kInputBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kAmber.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: kAmberDeep,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Add Stops ─────────────────────────────────────────────────────
  Widget _buildStopsSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shrink-wrapped button so it doesn't stretch the row
        GestureDetector(
          onTap: () {
            // TODO: add stops flow
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: kAmberSoft,
              border: Border.all(color: kInputBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: kInk, size: 15),
                const SizedBox(width: 4),
                Text(
                  'ADD STOPS',
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: kAmberDeep,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'NEW',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Dates ─────────────────────────────────────────────────────────
  Widget _buildDates(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildTripDateInput(
              context,
              'TRIP START',
              startDate,
              startTime,
              (res) {
                if (res != null) {
                  setState(() {
                    startDate = res['displayDate'] ?? res['date'];
                    startTime = res['time'];

                    final currentStart = _parseDateTime(startDate, startTime);
                    final currentEnd = _parseDateTime(endDate, endTime);
                    final minEnd = currentStart.add(const Duration(hours: 3));

                    if (currentEnd.isBefore(minEnd)) {
                      endDate = DateFormat('dd-MM-yyyy').format(minEnd);
                      endTime = DateFormat('hh:mm a').format(minEnd);
                    }
                  });
                }
              },
              minDateTime: _getInitialStartTime(),
            ),
          ),
          if (!widget.isOneWay) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _buildTripDateInput(
                context,
                'TRIP END',
                endDate,
                endTime,
                (res) {
                  if (res != null) {
                    final pickedDate = res['displayDate'] ?? res['date'];
                    final pickedTime = res['time'];

                    final currentStart = _parseDateTime(startDate, startTime);
                    final pickedEnd = _parseDateTime(pickedDate, pickedTime);
                    final minEnd = currentStart.add(const Duration(hours: 3));

                    if (pickedEnd.isBefore(minEnd)) {
                      setState(() {
                        endDate = DateFormat('dd-MM-yyyy').format(minEnd);
                        endTime = DateFormat('hh:mm a').format(minEnd);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Trip end time must be at least 3 hours after trip start time ($startTime). Set to $endTime.',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: Colors.black87,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      setState(() {
                        endDate = pickedDate;
                        endTime = pickedTime;
                      });
                    }
                  }
                },
                minDateTime: _parseDateTime(
                  startDate,
                  startTime,
                ).add(const Duration(hours: 3)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Clean, spacious date + time card matching user design
  Widget _buildTripDateInput(
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
                initialTime: subText,
                minDateTime: minDateTime,
              ),
        );
        onResult(result);
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
                mainAxisAlignment: MainAxisAlignment.center,
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

  // ── Explore Button ────────────────────────────────────────────────
  Widget _buildExploreButton() {
    return GestureDetector(
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
                  fontSize: 15.5,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: kInk, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
