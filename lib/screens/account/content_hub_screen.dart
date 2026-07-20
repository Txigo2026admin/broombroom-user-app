import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({super.key});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  final List<String> categories = ['All', 'Arts and Crafts', 'Beaches', 'Book local', 'Culture'];
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Content Hub',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Horizontal Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.shade400 : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index],
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Masonry-style Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildContentCard(
                          'assets/images/monastery.png',
                          '10 Spectacular Buddhist Monasteries in India',
                          isTall: false,
                        ),
                        const SizedBox(height: 16),
                        _buildContentCard(
                          'assets/images/chardham_banner.png',
                          '8 Monuments and 8 mysteries!',
                          isTall: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildContentCard(
                          'assets/images/turtle.png',
                          '5 Reasons To Attend Velas Turtle Festival',
                          isTall: true,
                        ),
                        const SizedBox(height: 16),
                        _buildContentCard(
                          'assets/images/beach_banner.png',
                          'A detailed guide on Char Dham Yatra in Uttarakhand',
                          isTall: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(String imagePath, String title, {bool isTall = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imagePath,
              height: isTall ? 240 : 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 16),
                    Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
