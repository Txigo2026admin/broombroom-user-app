import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:broomboom_user_app/screens/auth/otp_verification_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('OtpVerificationScreen renders 4-digit OTP boxes and accepts input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpVerificationScreen(phoneNumber: '+919876543210'),
      ),
    );

    await tester.pump();

    // Verify Screen mounts
    expect(find.byType(OtpVerificationScreen), findsOneWidget);
    expect(find.text('OTP Verification'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Verify & Proceed'), findsOneWidget);

    // Verify OTP input field is present and accepts digits
    final otpFinder = find.byKey(const Key('otp_text_field'));
    expect(otpFinder, findsOneWidget);

    await tester.enterText(otpFinder, '1234');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

