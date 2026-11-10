import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_review_screen.dart';
import 'booking_support_screen.dart';
import '../../data/services/car_service.dart';
import '../../data/models/car_category.dart';
import '../../data/services/distance_service.dart';
import '../../theme/app_theme.dart';

class CabSelectionScreen extends StatefulWidget {
  final String from;
  final String to;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final String date;
  final String time;
  final String? returnDate;
  final String? returnTime;
  final bool isOneWay;
  final String phoneNumber;
  final String? petType;
  final bool isRental;
  final int? packageHours;
  final int? includedKms;
  final bool isAirport;
  final String? airportDirection;
  final String? airportTerminal;
  final String? airportName;
  final double? initialDistance;

  const CabSelectionScreen({
    super.key,
    required this.from,
    required this.to,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.date,
    required this.time,
    this.returnDate,
    this.returnTime,
    required this.isOneWay,
    required this.phoneNumber,
    this.petType,
    this.isRental = false,
    this.packageHours,
    this.includedKms,
    this.isAirport = false,
    this.airportDirection,
    this.airportTerminal,
    this.airportName,
    this.initialDistance,
  });

  @override
  State<CabSelectionScreen> createState() => _CabSelectionScreenState();
}

class _CabSelectionScreenState extends State<CabSelectionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCarIndex = 0;
  late TabController _tabController;
  final ScrollController _carListScrollController = ScrollController();
  List<CarCategory> _carCategories = [];
  Map<String, double> _calculatedPrices = {};
  final Map<String, double> _perKmRates = {};
  final Map<String, double> _includedKms = {};
  final Map<String, Map<String, dynamic>> _pricingDetails = {};
  final Map<String, double> _originalPrices = {};
  bool _isLoading = true;
  double _distance = 0.0;
  bool _redirectedToOutstation = false;
  String? _airportRedirectNotice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchCarCategories();
  }

  Future<void> _fetchCarCategories() async {
    setState(() => _isLoading = true);

    // 1. Calculate one-way road distance using exact coordinates or geocoding
    double oneWayDist =
        (widget.initialDistance != null && widget.initialDistance! > 0)
            ? widget.initialDistance!
            : 0.0;
    if (widget.isRental) {
      oneWayDist = (widget.includedKms ?? 50).toDouble();
      _distance = oneWayDist;
    } else if (oneWayDist <= 0.0) {
      oneWayDist = await DistanceService.getDistance(
        widget.from,
        widget.to,
        pickupLat: widget.fromLat,
        pickupLng: widget.fromLng,
        dropLat: widget.toLat,
        dropLng: widget.toLng,
      );
      // For roundtrip, travel distance is 2x one-way
      _distance = widget.isOneWay ? oneWayDist : (oneWayDist * 2);
    } else {
      _distance = widget.isOneWay ? oneWayDist : (oneWayDist * 2);
    }

    // 2. Fetch all categories
    final categories = await CarService.getCarCategories();

    final bool exceedsAirportLimit =
        widget.isAirport && (oneWayDist > 25.0 || _distance > 25.0);
    if (exceedsAirportLimit) {
      _redirectedToOutstation = true;
      _airportRedirectNotice =
          'Trip distance (${(oneWayDist > 0 ? oneWayDist : _distance).toStringAsFixed(1)} km) exceeds 25 km airport limit. Automatically switched to Outstation cab pricing.';
    }

    // 3. Fetch prices for each category
    final String rideType =
        widget.isRental
            ? 'Rental'
            : ((widget.isAirport && !_redirectedToOutstation)
                ? 'Airport'
                : (widget.isOneWay ? 'Oneway' : 'Roundtrip'));

    Map<String, double> prices = {};
    for (var cat in categories) {
      final result = await CarService.calculatePrice(
        rideType: rideType,
        sourceCity: widget.from,
        destinationCity: widget.to,
        category: cat.name,
        distance: _distance,
        oneWayDistance: oneWayDist,
        pickupLat: widget.fromLat,
        pickupLng: widget.fromLng,
        dropLat: widget.toLat,
        dropLng: widget.toLng,
        days: 1,
        pickupDate: widget.date,
        pickupTime: widget.time,
        returnDate: widget.returnDate,
        returnTime: widget.returnTime,
        airportName: _redirectedToOutstation ? null : widget.airportName,
        packageHours: widget.packageHours,
        includedKms: widget.includedKms,
        petType: widget.petType,
        carryingPet: widget.petType != null,
        addons:
            widget.petType != null
                ? {'petAllowance': true, 'petCount': 1}
                : null,
      );
      if (result['success'] == true &&
          result['fare'] != null &&
          (result['fare'] as num) > 0) {
        prices[cat.name] = (result['fare'] as num).toDouble();
        _originalPrices[cat.name] =
            (result['originalFare'] as num?)?.toDouble() ??
            (prices[cat.name]! * 1.12);
        if (result['redirectedToOutstation'] == true || exceedsAirportLimit) {
          _redirectedToOutstation = true;
          _airportRedirectNotice =
              result['airportNotice']?.toString() ??
              'Trip distance exceeds 25 km airport limit. Automatically switched to Outstation cab pricing.';
        }
        if (_distance <= 0 &&
            result['distance'] != null &&
            (result['distance'] as num) > 0) {
          final resDist = (result['distance'] as num).toDouble();
          _distance = widget.isOneWay ? resDist : (resDist * 2);
        }

        final details =
            result['details'] is Map<String, dynamic>
                ? (result['details'] as Map<String, dynamic>)
                : (result['details'] is Map
                    ? Map<String, dynamic>.from(result['details'] as Map)
                    : null);
        if (details != null) {
          _pricingDetails[cat.name] = details;
        }

        if (widget.isRental && (widget.includedKms ?? 0) > 0) {
          _includedKms[cat.name] = (widget.includedKms!).toDouble();
        } else if (widget.isAirport &&
            details != null &&
            details['baseKms'] != null) {
          _includedKms[cat.name] = (details['baseKms'] as num).toDouble();
        } else if (details != null &&
            details['billableKms'] != null &&
            (details['billableKms'] as num) > 0) {
          _includedKms[cat.name] = (details['billableKms'] as num).toDouble();
        } else if (result['distance'] != null &&
            (result['distance'] as num) > 0) {
          _includedKms[cat.name] = (result['distance'] as num).toDouble();
        } else if (_distance > 0) {
          _includedKms[cat.name] = _distance;
        } else {
          _includedKms[cat.name] = widget.isOneWay ? 150.0 : 300.0;
        }

        double rate = 0.0;
        if (widget.isAirport &&
            details != null &&
            details['extraKmRate'] != null) {
          rate = (details['extraKmRate'] as num).toDouble();
        } else if (details != null &&
            details['extraKmRate'] != null &&
            (details['extraKmRate'] as num) > 0) {
          rate = (details['extraKmRate'] as num).toDouble();
        } else if (details != null &&
            details['ratePerKm'] != null &&
            (details['ratePerKm'] as num) > 0) {
          rate = (details['ratePerKm'] as num).toDouble();
        } else if (details != null &&
            details['perKm'] != null &&
            (details['perKm'] as num) > 0) {
          rate = (details['perKm'] as num).toDouble();
        }
        _perKmRates[cat.name] =
            rate > 0 ? rate : _getDefaultPerKmRate(cat.name, cat.perKmRate);
      } else {
        final fallbackRate = _getDefaultPerKmRate(cat.name, cat.perKmRate);
        final effectiveDist =
            _distance > 0 ? _distance : (widget.isOneWay ? 150.0 : 300.0);
        double calculated =
            (cat.baseFare +
                (effectiveDist * fallbackRate) +
                (cat.seater > 4 ? 300 : 250));
        if (widget.petType != null) {
          calculated += 1000.0;
        }
        prices[cat.name] =
            calculated > 0
                ? calculated
                : (cat.baseFare > 0 ? cat.baseFare : 2500.0);
        _perKmRates[cat.name] = fallbackRate;
        _includedKms[cat.name] = effectiveDist;
      }
    }

    // Sort categories safely
    final List<String> priorityOrder = [
      'sedan',
      'dzire',
      'etios',
      'ertiga',
      'suv',
      'crysta',
      'suv+',
      'luxury',
      '13',
      '17',
      '24',
      '25',
      'urbania',
      'traveller',
      'tempo',
    ];
    categories.sort((a, b) {
      String nameA = ((a.displayName) + (a.name)).toLowerCase();
      String nameB = ((b.displayName) + (b.name)).toLowerCase();
      int indexA = priorityOrder.indexWhere(
        (element) => nameA.contains(element),
      );
      int indexB = priorityOrder.indexWhere(
        (element) => nameB.contains(element),
      );
      if (indexA == -1) indexA = 99;
      if (indexB == -1) indexB = 99;
      return indexA.compareTo(indexB);
    });

    if (mounted) {
      setState(() {
        _carCategories = categories;
        _calculatedPrices = prices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMid,
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.from} - ${widget.to}',
          style: GoogleFonts.outfit(
            color: kInk,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAmberSoft,
                border: Border.all(color: kInputBorder),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: kAmberDeep,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip Info Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kInputBg,
              border: Border(
                bottom: BorderSide(color: kInputBorder.withValues(alpha: 0.7)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top line: Trip Type & Distance on Left, Modify on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _redirectedToOutstation
                                  ? 'Outstation Oneway (Airport Distance > 25 km)'
                                  : (widget.isAirport
                                      ? (widget.airportDirection ??
                                          'Airport Transfer')
                                      : (widget.isRental
                                          ? 'Rental Package'
                                          : (widget.isOneWay
                                              ? 'One Way'
                                              : 'Round Trip'))),
                              style: GoogleFonts.outfit(
                                color:
                                    _redirectedToOutstation
                                        ? const Color(0xFFC2410C)
                                        : kAmberDeep,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isRental) ...[
                            Flexible(
                              child: Text(
                                ' • ${widget.packageHours ?? 8} hrs / ${widget.includedKms ?? 80} km',
                                style: GoogleFonts.outfit(
                                  color: kInkSoft,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (_distance > 0) ...[
                            Flexible(
                              child: Text(
                                ' • ${_distance.toStringAsFixed(1)} km',
                                style: GoogleFonts.outfit(
                                  color: kInkSoft,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kAmberSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kInputBorder),
                        ),
                        child: Text(
                          'Modify',
                          style: GoogleFonts.outfit(
                            color: kInk,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Route line
                Text(
                  '${widget.from} - ${widget.to}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kInk,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                // Date & Time line: Left Pickup Date & Time, Right Return Date & Time in Round Trip
                if (!widget.isOneWay &&
                    widget.returnDate != null &&
                    widget.returnDate!.trim().isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: kAmberDeep,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Pickup: ${widget.date} | ${widget.time}',
                                style: GoogleFonts.outfit(
                                  color: kInkSoft,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.event_repeat_rounded,
                              size: 12,
                              color: kAmberDeep,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Return: ${widget.returnDate}${widget.returnTime != null && widget.returnTime!.trim().isNotEmpty ? " | ${widget.returnTime}" : ""}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  color: kInk,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: kAmberDeep,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Pickup: ${widget.date} | ${widget.time}',
                          style: GoogleFonts.outfit(
                            color: kInkSoft,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_redirectedToOutstation)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFC2410C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _airportRedirectNotice ??
                          'Trip distance exceeds 25 km airport limit. Automatically switched to Outstation cab pricing.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A3412),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Car Selection List with arrows & Main Car Details Card
          if (_isLoading)
            _buildLoadingView()
          else if (_carCategories.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No car categories available',
                  style: GoogleFonts.outfit(color: kInkSoft),
                ),
              ),
            )
          else ...[
            Container(
              height: 86,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  // Left arrow
                  GestureDetector(
                    onTap: () {
                      _carListScrollController.animateTo(
                        (_carListScrollController.offset - 80).clamp(
                          0.0,
                          _carListScrollController.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 20,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: kInkSoft,
                        size: 20,
                      ),
                    ),
                  ),
                  // Car list
                  Expanded(
                    child: ListView.builder(
                      controller: _carListScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: _carCategories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedCarIndex == index;
                        final car = _carCategories[index];
                        return GestureDetector(
                          onTap:
                              () => setState(() => _selectedCarIndex = index),
                          child: Container(
                            width: 76,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? kAmberSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: kInputBorder,
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  car.displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color: isSelected ? kInk : kInkSoft,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 54,
                                  height: 34,
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: kCardBg,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? kAmberDeep
                                              : kInputBorder,
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      _getCarImage(
                                        car.name,
                                        seater: car.seater,
                                      ),
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.directions_car,
                                                size: 18,
                                                color: kInkSoft,
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '₹ ${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? kAmberDeep : kInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Right arrow
                  GestureDetector(
                    onTap: () {
                      _carListScrollController.animateTo(
                        (_carListScrollController.offset + 80).clamp(
                          0.0,
                          _carListScrollController.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 20,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: kInkSoft,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Car Details Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                child: Column(
                  children: [
                    _buildMainCarCard(),
                    const SizedBox(height: 8),
                    _buildInfoBar(),
                    const SizedBox(height: 8),
                    _buildDetailsTabs(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainCarCard() {
    if (_carCategories.isEmpty) return const SizedBox.shrink();
    final safeIndex = _selectedCarIndex.clamp(0, _carCategories.length - 1);
    final car = _carCategories[safeIndex];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
        boxShadow: kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: name, subtitle, discount, price
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${car.seater} seater AC ${car.seater > 7 ? "Tempo" : "Cab"} ',
                            style: GoogleFonts.outfit(
                              color: kInkSoft,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: kAmberSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kInputBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '4.5',
                                style: GoogleFonts.outfit(
                                  color: kInk,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.star_rounded,
                                color: kAmberDeep,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // 11% OFF badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kAmberSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kInputBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: kAmberDeep,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '11% OFF',
                            style: GoogleFonts.outfit(
                              color: kInk,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Strikethrough price
                    Text(
                      '₹${(_originalPrices[car.name] ?? ((_calculatedPrices[car.name] ?? car.baseFare) * 1.12)).toInt()}',
                      style: GoogleFonts.outfit(
                        color: kInkSoft.withValues(alpha: 0.6),
                        decoration: TextDecoration.lineThrough,
                        fontSize: 11.5,
                      ),
                    ),
                    // Actual price - BIG
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kAmberDeep,
                          height: 1.05,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+ ₹${((_calculatedPrices[car.name] ?? car.baseFare) * 0.05).toInt()} Taxes and Charges',
                        style: GoogleFonts.outfit(color: kInkSoft, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: car image - prominent and clearly visible
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 115,
                  child: Builder(
                    builder: (context) {
                      final bool isTempo =
                          car.name.toLowerCase().contains('tempo') ||
                          car.name.toLowerCase().contains('traveller') ||
                          car.name.toLowerCase().contains('urbania') ||
                          car.seater > 7;

                      if (isTempo) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              _getCarImage(car.name, seater: car.seater),
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    decoration: BoxDecoration(
                                      color: kInputBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.airport_shuttle_rounded,
                                      color: kInkSoft,
                                      size: 44,
                                    ),
                                  ),
                            ),
                          ),
                        );
                      }

                      return Transform.scale(
                        scale: 1.15,
                        alignment: Alignment.centerRight,
                        child: Image.asset(
                          _getCarImage(car.name, seater: car.seater),
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  color: kInputBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: kInkSoft,
                                  size: 48,
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildInclusionItem(
            Icons.person_outline_rounded,
            'Driver allowance included',
          ),
          Builder(
            builder: (context) {
              final double dispKms = (_includedKms[car.name] ?? _distance);
              final int kmVal =
                  dispKms > 0 ? dispKms.toInt() : (widget.isOneWay ? 150 : 300);
              final double dispRate = (_perKmRates[car.name] ?? car.perKmRate);
              final int rateVal =
                  _getDefaultPerKmRate(car.name, dispRate).toInt();
              return _buildKmsIncludedItem(
                'Total kms: $kmVal kms',
                '| Fare rate: ',
                '₹$rateVal/km',
              );
            },
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: kInputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kInputBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: kAmberDeep, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Best price guaranteed for ${car.displayName}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kInk,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BookingReviewScreen(
                        from: widget.from,
                        to: widget.to,
                        fromLat: widget.fromLat,
                        fromLng: widget.fromLng,
                        toLat: widget.toLat,
                        toLng: widget.toLng,
                        date: widget.date,
                        time: widget.time,
                        returnDate: widget.returnDate,
                        returnTime: widget.returnTime,
                        isOneWay:
                            _redirectedToOutstation ? true : widget.isOneWay,
                        isRental: widget.isRental,
                        isAirport: widget.isAirport && !_redirectedToOutstation,
                        airportDirection:
                            _redirectedToOutstation
                                ? null
                                : widget.airportDirection,
                        airportTerminal:
                            _redirectedToOutstation
                                ? null
                                : widget.airportTerminal,
                        rentalPackage:
                            widget.isRental
                                ? '${widget.packageHours ?? 8} hrs / ${widget.includedKms ?? 80} kms'
                                : null,
                        carName:
                            widget.petType != null
                                ? 'Pet Friendly ${car.displayName} (${widget.petType})'
                                : car.displayName,
                        price:
                            '₹ ${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
                        phoneNumber: widget.phoneNumber,
                        petType: widget.petType,
                        pricingDetails: {
                          ...?_pricingDetails[car.name],
                          'includedKms': _includedKms[car.name],
                          'perKmRate':
                              _perKmRates[car.name] ?? car.perKmRate,
                          'distance':
                              _includedKms[car.name] ?? _distance,
                        },
                        originalPrice: _originalPrices[car.name],
                      ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kButtonShadow(),
              ),
              child: Center(
                child: Text(
                  'SELECT CAR',
                  style: GoogleFonts.outfit(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCarImage(String category, {int? seater}) {
    category = category.toLowerCase();
    if (category.contains('sedan')) {
      return 'assets/images/cab_sedan.png';
    }
    if (category.contains('suv+') ||
        category.contains('luxury') ||
        category.contains('crysta')) {
      return 'assets/images/cab_crysta.png';
    }
    if (category.contains('suv') || category.contains('ertiga')) {
      return 'assets/images/cab_ertiga.png';
    }
    if (category.contains('innova')) {
      return 'assets/images/cab_innova.png';
    }
    if (seater == 24 ||
        seater == 25 ||
        category.contains('24') ||
        category.contains('25')) {
      return 'assets/images/cab_tempo_24.png';
    }
    if (seater == 17 || category.contains('17')) {
      return 'assets/images/cab_tempo_17.png';
    }
    if (seater == 13 || category.contains('13')) {
      return 'assets/images/cab_tempo_13.png';
    }
    if (category.contains('urbania')) {
      return 'assets/images/cab_tempo_24.png';
    }
    if (category.contains('traveller') ||
        category.contains('tempo') ||
        category.contains('seater') ||
        (seater != null && seater > 7)) {
      return 'assets/images/cab_tempo_17.png';
    }
    if (category.contains('hatchback')) {
      return 'assets/images/cab_hatchback.png';
    }
    if (category.contains('test') || category.contains('wagon')) {
      return 'assets/images/cab_wagonr.png';
    }
    return 'assets/images/cab_sedan.png';
  }

  double _getDefaultPerKmRate(String categoryName, double fallbackRate) {
    if (fallbackRate > 0) {
      return fallbackRate;
    }
    final c = categoryName.toLowerCase();
    if ((c.contains('24') || c.contains('25')) &&
        (c.contains('traveller') ||
            c.contains('tempo') ||
            c.contains('urbania') ||
            c.contains('seater'))) {
      return 50.0;
    }
    if (c.contains('17') &&
        (c.contains('traveller') ||
            c.contains('tempo') ||
            c.contains('urbania') ||
            c.contains('seater'))) {
      return 45.0;
    }
    if (c.contains('13') &&
        (c.contains('traveller') ||
            c.contains('tempo') ||
            c.contains('urbania') ||
            c.contains('seater'))) {
      return 40.0;
    }
    if (c.contains('traveller') ||
        c.contains('tempo') ||
        c.contains('urbania')) {
      return 40.0;
    }
    if (c.contains('suv+') || c.contains('luxury') || c.contains('crysta')) {
      return 25.0;
    }
    if (c.contains('suv') || c.contains('ertiga') || c.contains('innova')) {
      return 20.0;
    }
    if (c.contains('sedan') || c.contains('dzire') || c.contains('etios')) {
      return 15.0;
    }
    if (c.contains('hatchback')) {
      return 15.0;
    }
    return 15.0;
  }

  Widget _buildInclusionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kAmberDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: kInk,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKmsIncludedItem(
    String boldPart,
    String normalPart,
    String rateBold,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded, size: 16, color: kAmberDeep),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                children: [
                  TextSpan(
                    text: boldPart,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: kInk,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' $normalPart',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: kInkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: rateBold,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: kAmberDeep,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInputBorder),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              Icons.currency_rupee_rounded,
              'Book Now\nat Zero Cost',
            ),
          ),

          _buildInfoDivider(),
          Expanded(
            child: _buildInfoItem(
              Icons.cancel_outlined,
              'Free Cancellations\nTill 1 Hour',
            ),
          ),

          _buildInfoDivider(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingSupportScreen()),
                );
              },
              child: _buildInfoItem(
                Icons.support_agent_rounded,
                '24x7\nCustomer Support',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: kAmberDeep, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDivider() {
    return Container(height: 28, width: 1, color: kInputBorder);
  }

  Widget _buildDetailsTabs() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: kInk,
            unselectedLabelColor: kInkSoft,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), kAmber],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'INCLUSIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'EXCLUSIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'FACILITIES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'T&C',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(children: _buildTabContent()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabContent() {
    final currentCar =
        _carCategories.isNotEmpty && _selectedCarIndex < _carCategories.length
            ? _carCategories[_selectedCarIndex]
            : null;
    final details =
        currentCar != null ? _pricingDetails[currentCar.name] : null;

    if (widget.isAirport && !_redirectedToOutstation) {
      final baseKms = 15;
      final maxKms = (details?['maxAirportKms'] as num?)?.toInt() ?? 25;
      final fare0to15 =
          (details?['fare0to15'] as num?)?.toInt() ??
          (details?['baseFare'] as num?)?.toInt() ??
          750;
      final fare15to25 = (details?['fare15to25'] as num?)?.toInt() ?? 1050;
      final waitingCharge =
          (details?['waitingChargePerHour'] ??
                  details?['waitingCharge'] as num?)
              ?.toInt() ??
          150;
      final nightAllowance =
          (details?['nightAllowance'] as num?)?.toInt() ?? 250;
      final activeTier =
          details?['tier']?.toString() ??
          (_distance <= 15 ? '0-15 km' : '15-25 km');

      switch (_tabController.index) {
        case 0: // INCLUSIONS
          return [
            _buildTabDetailItem(
              Icons.local_gas_station_rounded,
              'Fixed Tier Charges ($activeTier)',
            ),
            _buildTabDetailItem(
              Icons.route_rounded,
              'Total kms: $baseKms kms included',
            ),
            if (details?['extraKmRate'] != null)
              _buildTabDetailItem(
                Icons.currency_rupee_rounded,
                'Extra km rate: ₹${(details!['extraKmRate'] as num).toInt()}/km',
              ),
            _buildTabDetailItem(Icons.person_rounded, 'Driver Allowance'),
            _buildTabDetailItem(
              Icons.flight_land_rounded,
              'Airport Pickup / Drop Assistance',
            ),
          ];
        case 1: // EXCLUSIONS
          return [
            _buildTabDetailItem(Icons.receipt_long_rounded, 'Toll / State tax'),
            _buildTabDetailItem(
              Icons.account_balance_wallet_rounded,
              'GST (5%)',
            ),
            _buildTabDetailItem(
              Icons.local_parking_rounded,
              'Parking Charges (as per actuals)',
            ),
            _buildTabDetailItem(
              Icons.timer_outlined,
              'Waiting charges (after 60 mins of pickup time): ₹$waitingCharge/hour',
            ),
            _buildTabDetailItem(
              Icons.nightlight_round,
              'Night driving allowances: ₹$nightAllowance/- (Applicable once if ride time falls between 11 pm till 6 am)',
            ),
          ];
        case 2: // FACILITIES
          return [
            _buildTabDetailItem(Icons.ac_unit_rounded, 'Air Conditioner'),
            _buildTabDetailItem(Icons.luggage_rounded, 'Luggage Space'),
            _buildTabDetailItem(Icons.music_note_rounded, 'Music System'),
          ];
        case 3: // T&C
          return [
            _buildTabDetailItem(
              Icons.speed_rounded,
              '0-$baseKms km fixed charges: ₹$fare0to15',
            ),
            _buildTabDetailItem(
              Icons.speed_rounded,
              '$baseKms-$maxKms km fixed charges: ₹$fare15to25',
            ),
            _buildTabDetailItem(
              Icons.alt_route_rounded,
              'Beyond $maxKms km: Redirected to Outstation rates',
            ),
            _buildTabDetailItem(
              Icons.timer_outlined,
              'Waiting charges (after 60 mins of pickup time): ₹$waitingCharge/hour',
            ),
            _buildTabDetailItem(
              Icons.nightlight_round,
              'Night driving allowance: ₹$nightAllowance/- (11 PM till 6 AM)',
            ),
          ];
        default:
          return [];
      }
    }

    final slab =
        details?['slab']?.toString() ??
        (_distance <= 50
            ? '0-50 km'
            : _distance <= 100
            ? '51-100 km'
            : _distance <= 150
            ? '101-150 km'
            : _distance <= 200
            ? '151-200 km'
            : 'Upto 4000 km');
    final waitingCharge =
        (details?['waitingChargePerHour'] ?? details?['waitingCharge'] as num?)
            ?.toInt() ??
        150;
    final nightAllowance = (details?['nightAllowance'] as num?)?.toInt() ?? 250;

    switch (_tabController.index) {
      case 0: // INCLUSIONS
        final double dispKms =
            currentCar != null
                ? (_includedKms[currentCar.name] ?? _distance)
                : _distance;
        final int kmVal =
            dispKms > 0 ? dispKms.toInt() : (widget.isOneWay ? 150 : 300);
        final double dispRate =
            currentCar != null
                ? (_perKmRates[currentCar.name] ?? currentCar.perKmRate)
                : 12.0;
        final int rateVal =
            currentCar != null
                ? _getDefaultPerKmRate(currentCar.name, dispRate).toInt()
                : dispRate.toInt();

        return [
          _buildTabDetailItem(Icons.local_gas_station_rounded, 'Fuel Charges'),
          _buildTabDetailItem(Icons.person_rounded, 'Driver Allowance'),
          _buildTabDetailItem(
            Icons.route_rounded,
            'Total kms: $kmVal kms included',
          ),
          _buildTabDetailItem(
            Icons.currency_rupee_rounded,
            'Fare rate: ₹$rateVal/km',
          ),
          if (!widget.isOneWay) ...[
            _buildTabDetailItem(
              Icons.speed_rounded,
              'Roundtrip Distance ($slab - ${_distance.toStringAsFixed(0)} kms)',
            ),
            _buildTabDetailItem(
              Icons.timer_rounded,
              'Trip Duration: ${(details?['totalHours'] as num?)?.toInt() ?? 4} hrs',
            ),
          ],
        ];
      case 1: // EXCLUSIONS
        return [
          _buildTabDetailItem(Icons.receipt_long_rounded, 'Toll / State tax'),
          _buildTabDetailItem(Icons.account_balance_wallet_rounded, 'GST (5%)'),
          _buildTabDetailItem(Icons.local_parking_rounded, 'Parking Charges'),
          _buildTabDetailItem(
            Icons.timer_outlined,
            'Waiting charges (after 60 mins of pickup time): ₹$waitingCharge/hour',
          ),
          _buildTabDetailItem(
            Icons.nightlight_round,
            'Night driving allowances: ₹$nightAllowance/- (Applicable once if ride time falls between 11 pm till 6 am)',
          ),
        ];
      case 2: // FACILITIES
        return [
          _buildTabDetailItem(Icons.ac_unit_rounded, 'Air Conditioner'),
          _buildTabDetailItem(Icons.luggage_rounded, 'Luggage Space'),
          _buildTabDetailItem(Icons.music_note_rounded, 'Music System'),
        ];
      case 3: // T&C
        if (widget.isOneWay) {
          return [
            _buildTabDetailItem(
              Icons.timer_outlined,
              'Waiting charges (after 60 mins of pickup time): ₹$waitingCharge/hour',
            ),
            _buildTabDetailItem(
              Icons.nightlight_round,
              'Night driving allowances: ₹$nightAllowance/- (11 PM till 6 AM)',
            ),
          ];
        }
        return [
          _buildTabDetailItem(
            Icons.compare_arrows_rounded,
            'Fare evaluates: Distance fare vs Total hours fare (higher applies)',
          ),
          _buildTabDetailItem(
            Icons.timer_outlined,
            'Waiting charges (after 60 mins of pickup time): ₹$waitingCharge/hour',
          ),
          _buildTabDetailItem(
            Icons.nightlight_round,
            'Night driving allowances: ₹$nightAllowance/- (11 PM till 6 AM)',
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildTabDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAmberSoft,
              border: Border.all(color: kInputBorder),
            ),
            child: Icon(icon, size: 15, color: kAmberDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Please wait',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Image.asset(
                    'assets/images/loading_cab.gif',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/loading_car_yellow.png',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.directions_car_rounded,
                              size: 80,
                              color: kAmberDeep,
                            ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Looking for the best rates',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Finding reliable cabs at lowest prices...',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kInkSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: kAmberSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(kAmberDeep),
                      minHeight: 4.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
