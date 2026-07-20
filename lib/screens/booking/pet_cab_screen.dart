import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../home/widgets/date_time_picker.dart';
import 'booking_review_screen.dart';
import 'cab_selection_screen.dart';
import '../../widgets/city_autocomplete_field.dart';
import '../../data/cities.dart';

class PetCabScreen extends StatefulWidget {
  final String phoneNumber;
  const PetCabScreen({super.key, this.phoneNumber = '919243424225'});

  @override
  State<PetCabScreen> createState() => _PetCabScreenState();
}

class _PetCabScreenState extends State<PetCabScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  String _selectedPet = 'Dog';
  String startDate = DateFormat('E MMM dd').format(DateTime.now());
  String startTime = DateFormat('hh:mm a').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sanitized cabs, pet-friendly pilots, and extra care for your pets.',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),
                  _buildBookingCard(),
                  const SizedBox(height: 40),
                  _buildFeaturesSection(),
                  const SizedBox(height: 40),
                  _buildPetSelection(),
                  const SizedBox(height: 40),
                  _buildBookingButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.amber.shade800,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => Navigator.pop(context),
      ),
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
                  colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.white],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.amber.shade50),
      ),
      child: Column(
        children: [
          CityAutocompleteField(
            label: 'From',
            hint: 'Enter the City',
            icon: Icons.location_on_outlined,
            controller: _fromController,
          ),
          const SizedBox(height: 16),
          CityAutocompleteField(
            label: 'To',
            hint: 'Enter the City',
            icon: Icons.location_on,
            controller: _toController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  context,
                  Icons.calendar_today,
                  'Date',
                  startDate,
                  (res) => setState(() {
                    startDate = res['date'];
                    startTime = res['time'];
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  context,
                  Icons.access_time,
                  'Time',
                  startTime,
                  (res) => setState(() {
                    startDate = res['date'];
                    startTime = res['time'];
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildInfoBox(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Function(Map<String, dynamic>) onResult,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => DateTimePickerDialog(
            label: label,
            initialDate: value.contains('Select') ? 'Sun May 03' : value,
            initialTime: '07:00 AM',
          ),
        );
        if (result != null) {
          onResult(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade100)),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber.shade400, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(
                    value,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
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
        Text('Why Broom Boom Pet Cabs?', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureItem(Icons.cleaning_services, 'Deeply\nSanitized'),
            _buildFeatureItem(Icons.pets, 'No Cage\nNeeded'),
            _buildFeatureItem(Icons.health_and_safety, 'Safety\nHarness'),
            _buildFeatureItem(Icons.verified_user, 'Pet-Loving\nPilots'),
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
          decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.orange.shade700, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Your Pet Type', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade400 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.amber.shade400 : Colors.grey.shade300),
        ),
        child: Text(
          pet,
          style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_fromController.text.isEmpty || _toController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter pickup and destination cities')),
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
                isOneWay: true,
                phoneNumber: widget.phoneNumber,
                petType: _selectedPet,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.amber.withOpacity(0.4),
        ),
        child: Text(
          'BOOK PET CAB',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
        ),
      ),
    );
  }
}
