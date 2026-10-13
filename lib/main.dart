import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/booking/payment_verification_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Disable Flutter web inspector instrumentation to suppress AppInspector runtime errors
  if (kDebugMode) {
    // ignore: undefined_prefixed_name
    debugInstrumentationEnabled = false;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BroomBoom Cabs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.outfit().fontFamily,
        scaffoldBackgroundColor: kBgMid,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAmber,
          primary: kAmberDeep,
          secondary: kAmber,
          surface: kCardBg,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: kCardBg,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          iconTheme: const IconThemeData(color: kInk),
          titleTextStyle: GoogleFonts.outfit(
            color: kInk,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    final uri = Uri.base;

    // Check query parameters for Cashfree return URL
    String? bookingId = uri.queryParameters['booking_id'] ??
        uri.queryParameters['bookingId'] ??
        uri.queryParameters['booking_reference'];
    String? orderId =
        uri.queryParameters['order_id'] ?? uri.queryParameters['orderId'];

    // Also check fragment if hash-based routing is active (e.g. /#/?order_id=...)
    if ((bookingId == null || bookingId.isEmpty) && uri.hasFragment) {
      try {
        final frag = uri.fragment;
        final fragmentUri = Uri.parse(frag.startsWith('/') ? frag : '/$frag');
        bookingId ??= fragmentUri.queryParameters['booking_id'] ??
            fragmentUri.queryParameters['bookingId'] ??
            fragmentUri.queryParameters['booking_reference'];
        orderId ??= fragmentUri.queryParameters['order_id'] ??
            fragmentUri.queryParameters['orderId'];
      } catch (_) {}
    }

    // Fallback if Cashfree only returned order_id
    if ((bookingId == null || bookingId.isEmpty) &&
        orderId != null &&
        orderId.isNotEmpty) {
      bookingId = orderId;
    }

    // 1. If returning from Cashfree payment redirect:
    if (bookingId != null && bookingId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _targetScreen = PaymentVerificationScreen(
            bookingId: bookingId!,
            orderId: orderId,
          );
        });
      }
      return;
    }

    // 2. Otherwise check existing login session:
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final phone = await AuthService.getUserPhone();
      if (mounted) {
        setState(() {
          _targetScreen = HomeScreen(phoneNumber: phone ?? '');
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _targetScreen = const LoginScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetScreen == null) {
      return const Scaffold(
        backgroundColor: kBgMid,
        body: Center(
          child: CircularProgressIndicator(color: kAmberDeep),
        ),
      );
    }
    return _targetScreen!;
  }
}
