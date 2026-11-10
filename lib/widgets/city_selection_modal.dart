import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cities.dart';
import '../theme/app_theme.dart';

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
      filteredCities =
          allCities
              .where(
                (city) =>
                    city.name.toLowerCase().contains(query.toLowerCase()) ||
                    city.state.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: kInputBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: kInputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const Spacer(),
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
                      size: 18,
                      color: kInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: kInputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kInputBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCities,
                autofocus: true,
                style: GoogleFonts.outfit(
                  color: kInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for a city...',
                  hintStyle: GoogleFonts.outfit(
                    color: kInkSoft.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, color: kAmberDeep),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredCities.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: kInputBorder.withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                final city = filteredCities[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kAmberSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kInputBorder),
                      ),
                      child: const Icon(
                        Icons.location_city_rounded,
                        color: kAmberDeep,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      city.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                    subtitle: Text(
                      city.state,
                      style: GoogleFonts.outfit(fontSize: 12, color: kInkSoft),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: kAmberDeep,
                      size: 20,
                    ),
                    onTap: () => Navigator.pop(context, city),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
