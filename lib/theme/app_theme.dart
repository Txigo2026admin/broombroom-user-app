import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Light Artistic Palette (Yellow + White from Login Screen) ────────
const Color kAmber = Color(0xFFFFC107);
const Color kAmberDeep = Color(0xFFFF8A00);
const Color kAmberSoft = Color(0xFFFFF3D6);

const Color kInk = Color(0xFF2B1B00);
const Color kInkSoft = Color(0xFF6B5B3E);

const Color kCardBg = Color(0xFFFFFFFF);
const Color kInputBg = Color(0xFFFFFBF2);
const Color kInputBorder = Color(0xFFFFE082);

const Color kBgTop = Color(0xFFFFF8E1);
const Color kBgMid = Color(0xFFFFFDF7);
const Color kBgBottom = Color(0xFFFFFFFF);

// ── Gradients ────────────────────────────────────────────────────────
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFFFFD54F), Color(0xFFFFC107), kAmberDeep],
);

const LinearGradient kPrimaryGradientHover = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFFFFE082), Color(0xFFFFB300), kAmberDeep],
);

const LinearGradient kBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBgTop, kBgMid, kBgBottom],
  stops: [0.0, 0.55, 1.0],
);

const LinearGradient kHeaderShaderGradient = LinearGradient(
  colors: [Color(0xFFFFB300), kAmberDeep, Color(0xFFFF6D00)],
);

// ── Reusable Shadows ─────────────────────────────────────────────────
List<BoxShadow> kCardShadow({double opacity = 0.16}) => [
  BoxShadow(
    color: kAmber.withValues(alpha: opacity),
    blurRadius: 24,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> kButtonShadow({double opacity = 0.45}) => [
  BoxShadow(
    color: kAmber.withValues(alpha: opacity),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

// ── Reusable Component Helpers ───────────────────────────────────────
BoxDecoration kCardDecoration({double radius = 20, Color? bg}) => BoxDecoration(
  color: bg ?? kCardBg,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: kInputBorder.withValues(alpha: 0.8)),
  boxShadow: kCardShadow(),
);

BoxDecoration kInputContainerDecoration({double radius = 14}) => BoxDecoration(
  color: kInputBg,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: kInputBorder),
);

BoxDecoration kPrimaryButtonDecoration({
  double radius = 16,
  bool isPressed = false,
}) => BoxDecoration(
  gradient: kPrimaryGradient,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: isPressed ? [] : kButtonShadow(),
);

TextStyle kButtonTextStyle({double size = 16}) => GoogleFonts.outfit(
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: kInk,
  letterSpacing: 0.3,
);

TextStyle kHeadingTextStyle({
  double size = 18,
  FontWeight weight = FontWeight.bold,
}) => GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: kInk);

TextStyle kSubheadingTextStyle({double size = 13}) =>
    GoogleFonts.outfit(fontSize: size, color: kInkSoft);
