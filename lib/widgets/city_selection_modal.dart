import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cities.dart';

class CitySelectionModal extends StatefulWidget {
  final String title;
  const CitySelectionModal({super.key, required this.title});

  @override
  State<CitySelectionModal> createState() => _CitySelectionModalState();
}

class _CitySelectionModalState extends State<CitySelectionModal> {
  List<City> filteredCities = allCities;
  final TextEditingController _searchController = TextEditingController();

  void _filterCities(String query) {
    setState(() {
      filteredCities = allCities
          .where((city) =>
              city.name.toLowerCase().contains(query.toLowerCase()) ||
              city.state.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCities,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for a city...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredCities.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final city = filteredCities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.location_city, color: Colors.amber.shade400, size: 20),
                  ),
                  title: Text(city.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  subtitle: Text(city.state, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  onTap: () => Navigator.pop(context, city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
