import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:broomboom_user_app/screens/home/widgets/booking_card.dart';
import 'package:broomboom_user_app/screens/home/widgets/local_booking_card.dart';
import 'package:broomboom_user_app/screens/home/widgets/airport_booking_card.dart';
import 'package:broomboom_user_app/screens/home/widgets/package_booking_dialog.dart';

void main() {
  group('Trip start time buffers', () {
    testWidgets(
      'Outstation One Way and Round Trip start time is 1 hour after current time',
      (tester) async {
        final now = DateTime.now();
        final expectedMin = now.add(const Duration(hours: 1));
        int rem = expectedMin.minute % 15;
        int addM = rem == 0 ? 0 : (15 - rem);
        final expectedTime = expectedMin.add(Duration(minutes: addM));
        final expectedFormattedTime = DateFormat(
          'hh:mm a',
        ).format(expectedTime);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                isOneWay: true,
                onToggle: (_) {},
                phoneNumber: '9876543210',
              ),
            ),
          ),
        );

        expect(find.text(expectedFormattedTime), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Rental (Local) trip start time is 30 minutes after current time',
      (tester) async {
        final now = DateTime.now();
        final expectedMin = now.add(const Duration(minutes: 30));
        int rem = expectedMin.minute % 15;
        int addM = rem == 0 ? 0 : (15 - rem);
        final expectedTime = expectedMin.add(Duration(minutes: addM));
        final expectedFormattedTime = DateFormat(
          'hh:mm a',
        ).format(expectedTime);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LocalBookingCard(phoneNumber: '9876543210')),
          ),
        );

        expect(find.text(expectedFormattedTime), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('Airport trip start time is 15 minutes after current time', (
      tester,
    ) async {
      final now = DateTime.now();
      final expectedMin = now.add(const Duration(minutes: 15));
      int rem = expectedMin.minute % 15;
      int addM = rem == 0 ? 0 : (15 - rem);
      final expectedTime = expectedMin.add(Duration(minutes: addM));
      final expectedFormattedTime = DateFormat('hh:mm a').format(expectedTime);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AirportBookingCard(phoneNumber: '9876543210')),
        ),
      );

      expect(find.text(expectedFormattedTime), findsAtLeastNWidgets(1));
    });
  });

  group('Package redirect to search bar', () {
    testWidgets(
      'Tapping Explore Cabs in PackageBookingDialog triggers onExplore with package details',
      (tester) async {
        String? redirectedFrom;
        String? redirectedTo;
        String? redirectedStart;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PackageBookingDialog(
                packageName: 'CHARDHAM CAB PACKAGES',
                onExplore: ({
                  required fromCity,
                  required toCity,
                  required startDate,
                  required startTime,
                  endDate,
                  endTime,
                  fromLat,
                  fromLng,
                }) {
                  redirectedFrom = fromCity;
                  redirectedTo = toCity;
                  redirectedStart = startDate;
                },
              ),
            ),
          ),
        );

        // Verify Package Title & Fields
        expect(find.text('CHARDHAM CAB PACKAGES'), findsOneWidget);
        expect(find.text('EXPLORE CABS'), findsOneWidget);

        // Tap EXPLORE CABS
        await tester.tap(find.text('EXPLORE CABS'));
        await tester.pumpAndSettle();

        // Check onExplore was called with Haridwar as default pickup and Yamunotri itinerary
        expect(redirectedFrom, equals('Haridwar'));
        expect(redirectedTo, contains('Yamunotri'));
        expect(redirectedStart, isNotNull);
      },
    );
  });
}
