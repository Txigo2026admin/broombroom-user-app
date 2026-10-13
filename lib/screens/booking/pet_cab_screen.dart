import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../home/widgets/date_time_picker.dart';
import '../home/widgets/bottom_nav.dart';
import '../home/home_screen.dart';
import 'cab_selection_screen.dart';
import '../../widgets/city_autocomplete_field.dart';
import '../../theme/app_theme.dart';

class PetCabScreen extends StatefulWidget {
  final String phoneNumber;
  const PetCabScreen({super.key, this.phoneNumber = '919243424225'});

  @override
  State<PetCabScreen> createState() => _PetCabScreenState();
}

class _PetCabScreenState extends State<PetCabScreen> {
  // Service Type: 0 = One Way, 1 = Round Trip, 2 = Local Rental, 3 = Airport
  int _selectedServiceIndex = 0;

  // Controllers & FocusNodes
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _airportController = TextEditingController();
  final TextEditingController _airportAddressController = TextEditingController();
  final TextEditingController _rentalCityController = TextEditingController();

  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  final FocusNode _airportFocusNode = FocusNode();
  final FocusNode _airportAddressFocusNode = FocusNode();

  // Coordinates & Addresses
  double? _fromLat, _fromLng;
  double? _toLat, _toLng;
  double? _airportLat, _airportLng;
  double? _airportAddressLat, _airportAddressLng;
  double? _rentalCityLat, _rentalCityLng;

  String? _fromFullAddress;
  String? _toFullAddress;
  String? _airportFullAddress;
  String? _airportAddressFullAddress;
  String? _rentalCityFullAddress;

  // Rental Package
  int _selectedPackageIndex = 1; // 8 hrs / 80 kms default
  final List<Map<String, dynamic>> _rentalPackages = [
    {'time': '5 hrs', 'dist': '50 kms', 'hours': 5, 'kms': 50},
    {'time': '8 hrs', 'dist': '80 kms', 'hours': 8, 'kms': 80},
    {'time': '10 hrs', 'dist': '100 kms', 'hours': 10, 'kms': 100},
    {'time': '12 hrs', 'dist': '120 kms', 'hours': 12, 'kms': 120},
  ];

  // Airport transfer direction
  bool _isAirportPickup = true;

  // Pet & Dates
  String _selectedPet = 'Dog';
  String startDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String startTime = '07:00 AM';
  String endDate = DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 1)));
  String endSubtitle = DateFormat('EEEE').format(DateTime.now().add(const Duration(days: 1)));

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _airportController.dispose();
    _airportAddressController.dispose();
    _rentalCityController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _airportFocusNode.dispose();
    _airportAddressFocusNode.dispose();
    super.dispose();
  }

  void _navigateToCabs() {
    if (_selectedServiceIndex == 2) {
      // Local Rental
      if (_rentalCityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter pickup city for rental')),
        );
        return;
      }
      final pkg = _rentalPackages[_selectedPackageIndex];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CabSelectionScreen(
            from: _rentalCityFullAddress ?? _rentalCityController.text.trim(),
            to: 'Local (${pkg['time']})',
            fromLat: _rentalCityLat,
            fromLng: _rentalCityLng,
            date: startDate,
            time: startTime,
            isOneWay: true,
            isRental: true,
            packageHours: pkg['hours'] as int,
            includedKms: pkg['kms'] as int,
            phoneNumber: widget.phoneNumber,
            petType: _selectedPet,
          ),
        ),
      );
    } else if (_selectedServiceIndex == 3) {
      // Airport Transfer
      if (_airportController.text.trim().isEmpty || _airportAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter airport and address')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CabSelectionScreen(
            from: _isAirportPickup
                ? (_airportFullAddress ?? _airportController.text.trim())
                : (_airportAddressFullAddress ?? _airportAddressController.text.trim()),
            to: _isAirportPickup
                ? (_airportAddressFullAddress ?? _airportAddressController.text.trim())
                : (_airportFullAddress ?? _airportController.text.trim()),
            fromLat: _isAirportPickup ? _airportLat : _airportAddressLat,
            fromLng: _isAirportPickup ? _airportLng : _airportAddressLng,
            toLat: _isAirportPickup ? _airportAddressLat : _airportLat,
            toLng: _isAirportPickup ? _airportAddressLng : _airportLng,
            date: startDate,
            time: startTime,
            isOneWay: true,
            phoneNumber: widget.phoneNumber,
            petType: _selectedPet,
          ),
        ),
      );
    } else {
      // One Way or Round Trip
      if (_fromController.text.trim().isEmpty || _toController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter pickup and destination cities')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CabSelectionScreen(
            from: _fromFullAddress ?? _fromController.text.trim(),
            to: _toFullAddress ?? _toController.text.trim(),
            fromLat: _fromLat,
            fromLng: _fromLng,
            toLat: _toLat,
            toLng: _toLng,
            date: startDate,
            time: startTime,
            isOneWay: _selectedServiceIndex == 0,
            phoneNumber: widget.phoneNumber,
            petType: _selectedPet,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel With Your Furry Friends',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sanitized cabs, pet-friendly pilots, and extra care for your pets.',
                    style: GoogleFonts.outfit(fontSize: 13.5, color: kInkSoft),
                  ),
                  const SizedBox(height: 20),
                  _buildBookingCard(),
                  const SizedBox(height: 28),
                  _buildFeaturesSection(),
                  const SizedBox(height: 28),
                  _buildPetSelection(),
                  const SizedBox(height: 32),
                  _buildBookingButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedServiceIndex,
        onTap: (index) {
          // Switches the ride category (One Way, Round Trip, Local, Airport) with Pet inclusion intact!
          setState(() {
            _selectedServiceIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: kAmberDeep,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kCardBg,
            shape: BoxShape.circle,
            border: Border.all(color: kInputBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: kInk, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kCardBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kInputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                gradient: kPrimaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: 12, color: kInk),
            ),
            const SizedBox(width: 6),
            Text(
              'Pet Cabs',
              style: GoogleFonts.outfit(
                color: kInk,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(phoneNumber: widget.phoneNumber),
                ),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kInputBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 16, color: kAmberDeep),
                  const SizedBox(width: 4),
                  Text(
                    'Home',
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/pet_cab_hero.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                    kBgMid,
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kCardShadow(),
        border: Border.all(color: kInputBorder),
      ),
      child: Column(
        children: [
          Center(
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
                      Icons.pets_rounded,
                      color: kInk,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PET-FRIENDLY CAB BOOKING',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: kAmberDeep,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.favorite_rounded,
                    color: kAmberDeep,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Service Type Tabs (One Way, Round Trip, Rental, Airport)
          _buildServiceTypeSelector(),
          const SizedBox(height: 14),
          // Dynamic fields based on service type
          if (_selectedServiceIndex == 0 || _selectedServiceIndex == 1)
            _buildOutstationFields()
          else if (_selectedServiceIndex == 2)
            _buildRentalFields()
          else
            _buildAirportFields(),
        ],
      ),
    );
  }

  // ── Service Type Selector inside Card ─────────────────────────────
  Widget _buildServiceTypeSelector() {
    final List<Map<String, dynamic>> services = [
      {'title': 'ONE WAY', 'icon': Icons.directions_car_rounded},
      {'title': 'ROUND TRIP', 'icon': Icons.sync_alt_rounded},
      {'title': 'RENTAL', 'icon': Icons.location_city_rounded},
      {'title': 'AIRPORT', 'icon': Icons.airplanemode_active_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: kInputBg,
        border: Border.all(color: kInputBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(services.length, (index) {
          final isSelected = _selectedServiceIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedServiceIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? kPrimaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kAmber.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      services[index]['icon'] as IconData,
                      size: 16,
                      color: isSelected ? kInk : kInkSoft,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      services[index]['title'] as String,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? kInk : kInkSoft,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Outstation (One Way & Round Trip) ──────────────────────────────
  Widget _buildOutstationFields() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            Column(
              children: [
                CityAutocompleteField(
                  label: 'FROM',
                  hint: 'Enter Pickup City',
                  icon: Icons.trip_origin_rounded,
                  controller: _fromController,
                  focusNode: _fromFocusNode,
                  onCitySelected: (city) {
                    _fromLat = double.tryParse(city['lat']?.toString() ?? '');
                    _fromLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
                    _fromFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
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
                  hint: 'Enter Destination City',
                  icon: Icons.location_on_rounded,
                  controller: _toController,
                  focusNode: _toFocusNode,
                  onCitySelected: (city) {
                    _toLat = double.tryParse(city['lat']?.toString() ?? '');
                    _toLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
                    _toFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
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
            Padding(
              padding: const EdgeInsets.only(right: 14.0, bottom: 20),
              child: GestureDetector(
                onTap: () {
                  final temp = _fromController.text;
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
                    color: kCardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: kInputBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: kAmberDeep, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
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
                      });
                    }
                  },
                ),
              ),
              if (_selectedServiceIndex == 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTripDateInput(
                    context,
                    'TRIP END',
                    endDate,
                    endSubtitle,
                    (res) {
                      if (res != null) {
                        setState(() {
                          endDate = res['displayDate'] ?? res['date'];
                          endSubtitle = res['dayName'] ?? res['time'];
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Local Rental Fields ───────────────────────────────────────────
  Widget _buildRentalFields() {
    return Column(
      children: [
        // Package selector
        Container(
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: kInputBg,
            border: Border.all(color: kInputBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(_rentalPackages.length, (index) {
              final isSelected = _selectedPackageIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPackageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected ? kPrimaryGradient : null,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: kAmber.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _rentalPackages[index]['time'].toString(),
                          style: GoogleFonts.outfit(
                            color: isSelected ? kInk : kInkSoft,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _rentalPackages[index]['dist'].toString(),
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? kInk.withValues(alpha: 0.75)
                                : kInkSoft.withValues(alpha: 0.75),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
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
        const SizedBox(height: 10),
        CityAutocompleteField(
          label: 'CITY',
          hint: 'Enter Pickup City for Rental',
          icon: Icons.location_on_rounded,
          controller: _rentalCityController,
          onCitySelected: (city) {
            _rentalCityLat = double.tryParse(city['lat']?.toString() ?? '');
            _rentalCityLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
            _rentalCityFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
          },
          onChanged: (_) {
            _rentalCityLat = null;
            _rentalCityLng = null;
            _rentalCityFullAddress = null;
          },
        ),
        const SizedBox(height: 10),
        _buildTripDateInput(
          context,
          'TRIP START',
          startDate,
          startTime,
          (res) {
            if (res != null) {
              setState(() {
                startDate = res['displayDate'] ?? res['date'];
                startTime = res['time'];
              });
            }
          },
        ),
      ],
    );
  }

  // ── Airport Transfer Fields ───────────────────────────────────────
  Widget _buildAirportFields() {
    return Column(
      children: [
        // Pickup/Drop toggle
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: kInputBg,
            border: Border.all(color: kInputBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildAirportDirectionButton(true, 'PICKUP', 'Pickup from Airport'),
              _buildAirportDirectionButton(false, 'DROP', 'Drop to Airport'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CityAutocompleteField(
          label: 'AIRPORT',
          hint: 'Airport / City name',
          icon: Icons.airplanemode_active_rounded,
          controller: _airportController,
          focusNode: _airportFocusNode,
          onCitySelected: (city) {
            _airportLat = double.tryParse(city['lat']?.toString() ?? '');
            _airportLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
            _airportFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
            if (_airportAddressController.text.trim().isEmpty) {
              _airportAddressFocusNode.requestFocus();
            }
          },
          onChanged: (_) {
            _airportLat = null;
            _airportLng = null;
            _airportFullAddress = null;
          },
        ),
        const SizedBox(height: 8),
        CityAutocompleteField(
          label: _isAirportPickup ? 'DROP ADDRESS' : 'PICKUP ADDRESS',
          hint: 'Enter your destination address',
          icon: Icons.location_on_rounded,
          controller: _airportAddressController,
          focusNode: _airportAddressFocusNode,
          onCitySelected: (city) {
            _airportAddressLat = double.tryParse(city['lat']?.toString() ?? '');
            _airportAddressLng = double.tryParse((city['lon'] ?? city['lng'])?.toString() ?? '');
            _airportAddressFullAddress = (city['display_name'] ?? city['displayName'])?.toString();
            if (_airportController.text.trim().isEmpty) {
              _airportFocusNode.requestFocus();
            }
          },
          onChanged: (_) {
            _airportAddressLat = null;
            _airportAddressLng = null;
            _airportAddressFullAddress = null;
          },
        ),
        const SizedBox(height: 8),
        _buildTripDateInput(
          context,
          'TRIP START',
          startDate,
          startTime,
          (res) {
            if (res != null) {
              setState(() {
                startDate = res['displayDate'] ?? res['date'];
                startTime = res['time'];
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAirportDirectionButton(bool value, String title, String subText) {
    final isSelected = _isAirportPickup == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isAirportPickup = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isSelected ? kPrimaryGradient : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isSelected ? kInk : kInkSoft,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
    Function(Map<String, dynamic>?) onResult,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder:
              (context) => DateTimePickerDialog(
                label: label,
                initialDate: date,
                initialTime: subText.contains('M') ? subText : '07:00 AM',
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

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why BroomBoom Pet Cabs?',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kInk,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureItem(
              Icons.cleaning_services_rounded,
              'Deeply\nSanitized',
            ),
            _buildFeatureItem(Icons.pets_rounded, 'No Cage\nNeeded'),
            _buildFeatureItem(
              Icons.health_and_safety_rounded,
              'Safety\nHarness',
            ),
            _buildFeatureItem(
              Icons.verified_user_rounded,
              'Pet-Loving\nPilots',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kAmberSoft,
            shape: BoxShape.circle,
            border: Border.all(color: kInputBorder),
          ),
          child: Icon(icon, color: kAmberDeep, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kInk,
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Pet Type',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kInk,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildPetChip('Dog'),
            const SizedBox(width: 12),
            _buildPetChip('Cat'),
            const SizedBox(width: 12),
            _buildPetChip('Others'),
          ],
        ),
      ],
    );
  }

  Widget _buildPetChip(String pet) {
    bool isSelected = _selectedPet == pet;
    return GestureDetector(
      onTap: () => setState(() => _selectedPet = pet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(colors: [Color(0xFFFFD54F), kAmber])
                  : null,
          color: isSelected ? null : kInputBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? kAmberDeep : kInputBorder),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          pet,
          style: GoogleFonts.outfit(
            color: isSelected ? kInk : kInkSoft,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingButton() {
    return GestureDetector(
      onTap: _navigateToCabs,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kButtonShadow(),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BOOK PET CAB',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kInk,
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
