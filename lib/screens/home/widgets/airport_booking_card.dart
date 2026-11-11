import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'date_time_picker.dart';
import '../../../widgets/city_autocomplete_field.dart';
import '../../../widgets/airport_autocomplete_field.dart';
import '../../booking/cab_selection_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/airport.dart';
import '../../../data/services/distance_service.dart';
import '../../../data/services/booking_service.dart';

class AirportBookingCard extends StatefulWidget {
  final String? phoneNumber;

  const AirportBookingCard({super.key, this.phoneNumber});

  @override
  State<AirportBookingCard> createState() => _AirportBookingCardState();
}

class _AirportBookingCardState extends State<AirportBookingCard> {
  final TextEditingController _airportController = TextEditingController();
  final FocusNode _airportFocusNode = FocusNode();

  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  double? _addressLat;
  double? _addressLng;
  String? _addressFullAddress;

  Airport? _selectedAirport;
  String? _selectedTerminal;
  final List<String> _customTerminals = [];

  bool isPickup = true;
  double? _estimatedDistance;
  late String startDate;
  late String startTime;

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
    startDate = DateFormat('dd-MM-yyyy').format(startDt);
    startTime = DateFormat('hh:mm a').format(startDt);
  }

  @override
  void dispose() {
    _airportController.dispose();
    _airportFocusNode.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAirportDistancePreview() async {
    final fromLat = isPickup ? _selectedAirport?.lat : _addressLat;
    final fromLng = isPickup ? _selectedAirport?.lon : _addressLng;
    final toLat = isPickup ? _addressLat : _selectedAirport?.lat;
    final toLng = isPickup ? _addressLng : _selectedAirport?.lon;

    if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
      try {
        final dist = await DistanceService.getDistance(
          _airportController.text.trim(),
          _addressController.text.trim(),
          pickupLat: fromLat,
          pickupLng: fromLng,
          dropLat: toLat,
          dropLng: toLng,
        );
        if (mounted) {
          setState(() => _estimatedDistance = dist);
        }
      } catch (_) {}
    }
  }

  void _navigateToCabs() {
    if (_selectedAirport == null && _airportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an airport from the search bar'),
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPickup
                ? 'Please enter your drop address'
                : 'Please enter your pickup address',
          ),
        ),
      );
      return;
    }

    final terminalSuffix =
        (_selectedTerminal != null &&
                _selectedTerminal!.isNotEmpty &&
                _selectedTerminal != 'Any Terminal')
            ? ' - $_selectedTerminal'
            : '';
    final airportFormatted =
        _selectedAirport != null
            ? '${_selectedAirport!.name} (${_selectedAirport!.code})$terminalSuffix'
            : _airportController.text.trim();

    final fromLocation =
        isPickup
            ? airportFormatted
            : (_addressFullAddress ?? _addressController.text.trim());
    final toLocation =
        isPickup
            ? (_addressFullAddress ?? _addressController.text.trim())
            : airportFormatted;

    final fromLat = isPickup ? _selectedAirport?.lat : _addressLat;
    final fromLng = isPickup ? _selectedAirport?.lon : _addressLng;
    final toLat = isPickup ? _addressLat : _selectedAirport?.lat;
    final toLng = isPickup ? _addressLng : _selectedAirport?.lon;

    // Instant sync to Admin Booking Leads
    BookingService.recordSearchLead(
      pickupAddress: fromLocation,
      dropAddress: toLocation,
      serviceType: 'Airport',
      airportDirection: isPickup ? 'Pickup from airport' : 'Drop to airport',
      airportTerminal: _selectedTerminal,
      pickupDate: startDate,
      pickupTime: startTime,
      pickupLat: fromLat?.toString(),
      pickupLng: fromLng?.toString(),
      dropLat: toLat?.toString(),
      dropLng: toLng?.toString(),
      customerMobile: widget.phoneNumber,
    );

    // Navigate directly to the Cab Selection (calculation) page!
    // If distance > 25 km, CabSelectionScreen automatically switches to Outstation One Way pricing and cabs.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CabSelectionScreen(
              from: fromLocation,
              to: toLocation,
              fromLat: fromLat,
              fromLng: fromLng,
              toLat: toLat,
              toLng: toLng,
              date: startDate,
              time: startTime,
              isOneWay: true,
              isAirport: true,
              initialDistance: _estimatedDistance,
              airportDirection:
                  isPickup ? 'Pickup from airport' : 'Drop to airport',
              airportTerminal: _selectedTerminal,
              airportName: _selectedAirport?.name,
              phoneNumber: widget.phoneNumber ?? '919243424225',
            ),
      ),
    );
  }

  void _onTerminalChipTapped(String terminal) {
    setState(() {
      _selectedTerminal = terminal;
    });
  }

  Future<void> _showCustomTerminalDialog() async {
    final textController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Color(0xFFFF8F00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enter Terminal',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type any terminal or gate for ${_selectedAirport?.name ?? "this airport"}:',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Terminal 3, Terminal 1D, Cargo Gate',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFDF5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD54F),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8F00),
                      width: 1.8,
                    ),
                  ),
                ),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                ),
                onSubmitted: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.pop(ctx, trimmed);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                final trimmed = textController.text.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.pop(ctx, trimmed);
                }
              },
              child: Text(
                'Select Terminal',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (customName != null && customName.trim().isNotEmpty) {
      final trimmed = customName.trim();
      setState(() {
        if (!_customTerminals.contains(trimmed)) {
          _customTerminals.add(trimmed);
        }
        _selectedTerminal = trimmed;
      });
    }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6.5,
              ),
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
                      Icons.flight_takeoff_rounded,
                      color: kInk,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RELIABLE AIRPORT TRANSFERS',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: kAmberDeep,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: kAmberDeep,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pickup / Drop toggle
          Container(
            height: 46,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: kInputBg,
              border: Border.all(color: kInputBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildToggleButton(true, 'PICKUP', 'PICKUP FROM AIRPORT'),
                _buildToggleButton(false, 'DROP', 'DROP TO AIRPORT'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Airport Search Bar (Clicking opens dropdown of all airports from backend)
          AirportAutocompleteField(
            label: 'AIRPORT',
            hint: 'Search airport or click to view all (e.g. CCU)',
            icon: Icons.airplanemode_active_rounded,
            controller: _airportController,
            focusNode: _airportFocusNode,
            onAirportSelected: (airport, defaultTerminal) {
              setState(() {
                _selectedAirport = airport;
                _customTerminals.clear();
                _selectedTerminal =
                    defaultTerminal ??
                    (airport.terminals.isNotEmpty
                        ? airport.terminals.first
                        : 'Terminal 1');
              });
              if (_addressController.text.trim().isEmpty) {
                _addressFocusNode.requestFocus();
              }
            },
            onChanged: (val) {
              if (val.trim().isEmpty) {
                setState(() {
                  _selectedAirport = null;
                  _selectedTerminal = null;
                  _customTerminals.clear();
                });
              }
            },
          ),

          // WHEN AN AIRPORT IS CLICKED, THEN ONLY THIS BAR APPEARS TO SELECT THE TERMINAL
          if (_selectedAirport != null) ...[
            const SizedBox(height: 10),
            _buildTerminalSelector(),
          ],
          const SizedBox(height: 8),

          // Address Input (Pickup or Drop based on toggle)
          CityAutocompleteField(
            label: isPickup ? 'DROP ADDRESS' : 'PICKUP ADDRESS',
            hint: 'Enter your destination address / locality',
            icon: Icons.location_on_rounded,
            controller: _addressController,
            focusNode: _addressFocusNode,
            onCitySelected: (city) {
              _addressLat = double.tryParse(city['lat']?.toString() ?? '');
              _addressLng = double.tryParse(
                (city['lon'] ?? city['lng'])?.toString() ?? '',
              );
              _addressFullAddress =
                  (city['display_name'] ?? city['displayName'])?.toString();
              _checkAirportDistancePreview();
            },
            onChanged: (_) {
              _addressLat = null;
              _addressLng = null;
              _addressFullAddress = null;
              if (_estimatedDistance != null) {
                setState(() => _estimatedDistance = null);
              }
            },
          ),
          if (_estimatedDistance != null && _estimatedDistance! > 25.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFC2410C),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trip distance is ${_estimatedDistance!.toStringAsFixed(1)} km (> 25 km limit). Cabs will calculate with Outstation One Way pricing.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Trip Start Date & Time
          _buildTripDateInput(
            context,
            'TRIP START',
            startDate,
            startTime,
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 14),

          // Explore Button
          GestureDetector(
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
                        fontSize: 16,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: kInk,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Exact matching design from the user's uploaded image
  Widget _buildTerminalSelector() {
    final baseTerminals =
        (_selectedAirport?.terminals != null &&
                _selectedAirport!.terminals.isNotEmpty)
            ? _selectedAirport!.terminals
            : ['Terminal 1', 'Terminal 2'];

    // Combine airport terminals, any custom entered terminals, plus 'Any Terminal'
    final List<String> terminals = [];
    for (final t in baseTerminals) {
      if (!terminals.contains(t)) terminals.add(t);
    }
    for (final t in _customTerminals) {
      if (!terminals.contains(t)) terminals.add(t);
    }
    if (!terminals.contains('Any Terminal')) {
      terminals.add('Any Terminal');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_takeoff_rounded,
                color: Color(0xFFFF8F00),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'SELECTED AIRPORT TERMINALS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF8F00),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...terminals.map((terminal) {
                  final isSelected = _selectedTerminal == terminal;
                  return GestureDetector(
                    onTap: () => _onTerminalChipTapped(terminal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFB300),
                                    Color(0xFFFF8F00),
                                  ],
                                )
                                : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFFFF8F00)
                                  : const Color(0xFFFFD54F),
                          width: 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF8F00,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [],
                      ),
                      child: Text(
                        terminal,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color:
                              isSelected
                                  ? Colors.black
                                  : const Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _showCustomTerminalDialog,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFFFF8F00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Other',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF8F00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(colors: [Color(0xFFFFD54F), kAmber])
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? kInk : kInkSoft,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subText,
                style: GoogleFonts.outfit(
                  color:
                      isSelected
                          ? kInk.withValues(alpha: 0.7)
                          : kInkSoft.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripDateInput(
    BuildContext context,
    String label,
    String date,
    String subText,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder:
              (context) => DateTimePickerDialog(
                label: label,
                initialDate: date,
                initialTime: subText,
                minDateTime: _getInitialStartTime(),
              ),
        );
        if (result != null) {
          setState(() {
            startDate = result['displayDate'] ?? result['date'];
            startTime = result['time'];
          });
        }
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
}
