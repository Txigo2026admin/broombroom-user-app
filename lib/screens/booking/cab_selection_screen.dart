import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_review_screen.dart';
import '../../data/services/car_service.dart';
import '../../data/models/car_category.dart';
import '../../data/services/distance_service.dart';

class CabSelectionScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String time;
  final bool isOneWay;
  final String phoneNumber;
  final String? petType;

  const CabSelectionScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.isOneWay,
    required this.phoneNumber,
    this.petType,
  });

  @override
  State<CabSelectionScreen> createState() => _CabSelectionScreenState();
}

class _CabSelectionScreenState extends State<CabSelectionScreen> with SingleTickerProviderStateMixin {
  int _selectedCarIndex = 0;
  late TabController _tabController;
  final ScrollController _carListScrollController = ScrollController();
  List<CarCategory> _carCategories = [];
  Map<String, double> _calculatedPrices = {};
  Map<String, double> _perKmRates = {};
  bool _isLoading = true;
  double _distance = 0.0;

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
    
    // 1. Calculate distance once
    _distance = await DistanceService.getDistance(widget.from, widget.to);
    
    // 2. Fetch all categories
    final categories = await CarService.getCarCategories();
    
    // 3. Fetch prices for each category
    Map<String, double> prices = {};
    for (var cat in categories) {
      final result = await CarService.calculatePrice(
        rideType: widget.isOneWay ? 'Oneway' : 'Roundtrip',
        sourceCity: widget.from,
        destinationCity: widget.to,
        category: cat.name,
        distance: _distance,
        days: 1, // Default to 1 day for now
      );
      if (result.containsKey('fare')) {
        prices[cat.name] = (result['fare'] as num).toDouble();
        if (result.containsKey('details') && result['details'].containsKey('perKm')) {
          _perKmRates[cat.name] = (result['details']['perKm'] as num).toDouble();
        }
      } else {
        prices[cat.name] = cat.baseFare; // Fallback
      }
    }

    // Sort categories (existing logic)
    final List<String> priorityOrder = ['hatchback', 'ertiga', 'sedan', 'luxury', 'crysta'];
    categories.sort((a, b) {
      String nameA = (a.displayName + a.name).toLowerCase();
      String nameB = (b.displayName + b.name).toLowerCase();
      int indexA = priorityOrder.indexWhere((element) => nameA.contains(element));
      int indexB = priorityOrder.indexWhere((element) => nameB.contains(element));
      if (indexA == -1) indexA = 99;
      if (indexB == -1) indexB = 99;
      return indexA.compareTo(indexB);
    });

    setState(() {
      _carCategories = categories;
      _calculatedPrices = prices;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.from} - ${widget.to}',
          style: GoogleFonts.outfit(
            color: Colors.amber.shade400,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.amber.shade400, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isOneWay ? 'One Way' : 'Round Trip',
                        style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.from} - ${widget.to}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pickup Details: ${widget.date} | ${widget.time}',
                        style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('Modify Booking', style: GoogleFonts.outfit(color: Colors.amber, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Car Selection List with arrows
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _carCategories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No car categories available'),
                    )
                  : SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          // Left arrow
                          GestureDetector(
                            onTap: () {
                              _carListScrollController.animateTo(
                                (_carListScrollController.offset - 100).clamp(0.0, _carListScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 24,
                              alignment: Alignment.center,
                              child: Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 22),
                            ),
                          ),
                          // Car list
                          Expanded(
                            child: ListView.builder(
                              controller: _carListScrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _carCategories.length,
                              itemBuilder: (context, index) {
                                bool isSelected = _selectedCarIndex == index;
                                final car = _carCategories[index];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCarIndex = index),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          car.displayName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.amber : Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.amber : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Image.asset(
                                            _getCarImage(car.name),
                                            height: 38,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.directions_car, size: 24, color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹ ${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected ? Colors.amber : Colors.black,
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
                                (_carListScrollController.offset + 100).clamp(0.0, _carListScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 24,
                              alignment: Alignment.center,
                              child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

          // Main Car Details Card
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _carCategories.isEmpty
                    ? const Center(child: Text('No car details available'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            _buildMainCarCard(),
                            const SizedBox(height: 10),
                            _buildInfoBar(),
                            const SizedBox(height: 10),
                            _buildDetailsTabs(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCarCard() {
    final car = _carCategories[_selectedCarIndex];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: name, subtitle, discount, price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.displayName,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('${car.seater} seater AC Cab ',
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Text('4.5',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              const Icon(Icons.star, color: Colors.white, size: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 11% OFF badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 12),
                          const SizedBox(width: 4),
                          Text('11% OFF',
                              style: GoogleFonts.outfit(color: Colors.green.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Strikethrough price
                    Text('₹${((_calculatedPrices[car.name] ?? car.baseFare) * 1.12).toInt()}',
                        style: GoogleFonts.outfit(color: Colors.red.shade400, decoration: TextDecoration.lineThrough, decorationColor: Colors.red.shade400, fontSize: 16)),
                    // Actual price - BIG
                    Text(
                      '₹${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                    ),
                    Text(
                      '+ ₹${((_calculatedPrices[car.name] ?? car.baseFare) * 0.05).toInt()} Charges and Taxes',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Right side: car image
              Image.asset(
                _getCarImage(car.name),
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.directions_car, color: Colors.grey.shade400, size: 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInclusionItem(Icons.person_outline, 'Driver allowance included'),
          _buildKmsIncludedItem(
            '${_distance.toInt()} kms',
            'included | Post limit: ',
            '₹${(_perKmRates[car.name] ?? car.perKmRate).toInt()}/km',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.new_releases_outlined, color: Colors.amber.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Best price guaranteed for ${car.displayName}',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingReviewScreen(
                      from: widget.from,
                      to: widget.to,
                      date: widget.date,
                      time: widget.time,
                      isOneWay: widget.isOneWay,
                      carName: widget.petType != null
                          ? 'Pet Friendly ${car.displayName} (${widget.petType})'
                          : car.displayName,
                      price: '₹ ${(_calculatedPrices[car.name] ?? car.baseFare).toInt()}',
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
                'SELECT CAR',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCarImage(String category) {
    category = category.toLowerCase();
    if (category.contains('hatchback')) return 'assets/images/cab_hatchback.png';
    if (category.contains('sedan')) return 'assets/images/cab_sedan.png';
    if (category.contains('ertiga')) return 'assets/images/cab_ertiga.png';
    if (category.contains('crysta')) return 'assets/images/cab_crysta.png';
    if (category.contains('innova')) return 'assets/images/cab_innova.png';
    if (category.contains('test') || category.contains('wagon')) return 'assets/images/cab_wagonr.png';
    return 'assets/images/cab_sedan.png';
  }

  Widget _buildInclusionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildKmsIncludedItem(String boldPart, String normalPart, String rateBold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(Icons.speed, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: boldPart,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' $normalPart',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: rateBold,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(Icons.currency_rupee, 'Book Now\nat Zero Cost'),
          _buildInfoDivider(),
          _buildInfoItem(Icons.cancel_outlined, 'Free Cancellations\nTill 1 Hour'),
          _buildInfoDivider(),
          _buildInfoItem(Icons.support_agent, '24x7\nCustomer Support'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber.shade400, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
        ),
      ],
    );
  }

  Widget _buildInfoDivider() {
    return Container(height: 30, width: 1, color: Colors.amber.shade200);
  }

  Widget _buildDetailsTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicator: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(child: Text('INCLUSIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Tab(child: Text('EXCLUSIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Tab(child: Text('FACILITIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Tab(child: Text('T&C', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabContent() {
    switch (_tabController.index) {
      case 0: // INCLUSIONS
        return [
          _buildTabDetailItem(Icons.local_gas_station_outlined, 'Fuel Charges'),
          _buildTabDetailItem(Icons.person_outline, 'Driver Allowance'),
          if (!widget.isOneWay) ...[
            _buildTabDetailItem(Icons.timer_outlined, 'Driving Allowance'),
            _buildTabDetailItem(Icons.hourglass_empty_outlined, 'Hour Charges'),
          ],
        ];
      case 1: // EXCLUSIONS
        return [
          _buildTabDetailItem(Icons.receipt_long_outlined, 'Toll / State tax'),
          _buildTabDetailItem(Icons.account_balance_wallet_outlined, 'GST (5%)'),
          _buildTabDetailItem(Icons.local_parking_outlined, 'Parking Charges'),
        ];
      case 2: // FACILITIES
        return [
          _buildTabDetailItem(Icons.ac_unit, 'Air Conditioner'),
          _buildTabDetailItem(Icons.luggage, 'Luggage Space'),
          _buildTabDetailItem(Icons.music_note, 'Music System'),
        ];
      case 3: // T&C
        return [
          _buildTabDetailItem(Icons.info_outline, 'Night allowance applicable (10 PM - 6 AM)'),
          _buildTabDetailItem(Icons.speed, 'Extra kms will be charged per km rate'),
          _buildTabDetailItem(Icons.article_outlined, 'Toll and state tax as per actuals'),
        ];
      default:
        return [];
    }
  }

  Widget _buildTabDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
