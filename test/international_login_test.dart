import 'package:broomboom_user_app/data/services/auth_service.dart';
import 'package:broomboom_user_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AuthService.isIndiaCountry', () {
    test('identifies India correctly and excludes other countries', () {
      expect(
        AuthService.isIndiaCountry(countryCode: 'IN', phoneCode: '91'),
        isTrue,
      );
      expect(
        AuthService.isIndiaCountry(countryCode: 'in', phoneCode: '+91'),
        isTrue,
      );
      expect(
        AuthService.isIndiaCountry(countryCode: 'US', phoneCode: '1'),
        isFalse,
      );
      expect(
        AuthService.isIndiaCountry(countryCode: 'GB', phoneCode: '44'),
        isFalse,
      );
      expect(
        AuthService.isIndiaCountry(countryCode: 'AE', phoneCode: '971'),
        isFalse,
      );
    });
  });

  group('LoginScreen country-code-wise verification flow', () {
    testWidgets(
      'India (+91) keeps phone OTP flow; outside India switches to Email/Google without OTP',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );
        await tester.pump(const Duration(milliseconds: 400));

        // Default state: India (+91) -> phone OTP only
        expect(find.text('+91'), findsOneWidget);
        expect(find.text('PHONE NUMBER'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Continue with Email'), findsNothing);
        expect(find.text('Continue with Google'), findsNothing);

        // Open country picker and choose United States (+1)
        await tester.tap(find.text('+91'));
        await tester.pump(const Duration(milliseconds: 400));

        final searchField = find.byType(TextField).last;
        await tester.enterText(searchField, 'United States');
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.textContaining('United States'),
              )
              .first,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Outside India state -> skips OTP, shows Email ID and Google login
        expect(find.text('+1'), findsOneWidget);
        expect(find.text('MOBILE NUMBER (OPTIONAL)'), findsOneWidget);
        expect(
          find.text(
            'No SMS OTP needed outside India. Verify using Email ID or Google.',
          ),
          findsOneWidget,
        );
        expect(find.text('EMAIL ID'), findsOneWidget);
        expect(find.text('Continue with Email'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue'), findsNothing);

        // Switch back to India (+91) -> restores SMS OTP flow only
        await tester.tap(find.text('+1'));
        await tester.pump(const Duration(milliseconds: 400));

        await tester.enterText(find.byType(TextField).last, 'India');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.textContaining('India'),
              )
              .first,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('+91'), findsOneWidget);
        expect(find.text('PHONE NUMBER'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Continue with Email'), findsNothing);
        expect(find.text('Continue with Google'), findsNothing);
      },
    );
  });
}
