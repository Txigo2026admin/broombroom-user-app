import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ExpertSection extends StatelessWidget {
  const ExpertSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAY HELLO TO,',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: kAmberDeep,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'YOUR TRAVEL EXPERT',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get expert advice for smarter travel plans!',
                  style: GoogleFonts.outfit(fontSize: 11, color: kInkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kInputBorder),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 16,
                        color: kAmberDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Call Expert | 24x7',
                        style: GoogleFonts.outfit(
                          color: kInk,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
