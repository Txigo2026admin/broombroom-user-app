import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpertSection extends StatelessWidget {
  const ExpertSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAY HELLO TO,',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber.shade400, fontWeight: FontWeight.bold),
                ),
                Text(
                  'YOUR TRAVEL EXPERT',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Get expert advice for smarter travel plans!',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call, size: 16, color: Colors.black),
            label: Text(
              'Call Expert | 24x7',
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
