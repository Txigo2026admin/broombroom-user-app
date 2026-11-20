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

    // Verify individual OTP digit input fields are present and accept digits
    final otp0 = find.byKey(const Key('otp_field_0'));
    final otp1 = find.byKey(const Key('otp_field_1'));
    final otp2 = find.byKey(const Key('otp_field_2'));
    final otp3 = find.byKey(const Key('otp_field_3'));

    expect(otp0, findsOneWidget);
    expect(otp1, findsOneWidget);
    expect(otp2, findsOneWidget);
    expect(otp3, findsOneWidget);

    await tester.enterText(otp0, '1');
    await tester.enterText(otp1, '2');
    await tester.enterText(otp2, '3');
    await tester.enterText(otp3, '4');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

