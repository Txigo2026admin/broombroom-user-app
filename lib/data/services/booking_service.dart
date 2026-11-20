import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  static Future<List<Booking>> getMyBookings() async {
    try {
      final response = await ApiService.get('/bookings');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Booking.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  static Future<Booking?> createBooking(Booking booking) async {
    try {
      final payload = booking.toJson();
      payload['source'] = 'BroomBoom App';
      final response = await ApiService.post('/bookings', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Booking.fromJson(jsonDecode(response.body));
      } else {
        print('Create booking failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  /// Records any user search inquiry as an instant Booking Lead via /api/booking-leads
  static Future<Map<String, dynamic>?> recordSearchLead({
    required String pickupAddress,
    required String dropAddress,
    String? fromCity,
    String? toCity,
    String? distance,
    String? duration,
    required String serviceType,
    String? wayType,
    String? airportDirection,
    String? airportTerminal,
    String? rentalPackage,
    String? pickupDate,
    String? pickupTime,
    String? returnDate,
    String? returnTime,
    String? vehicleCategory,
    int? seater,
    double? fare,
    bool petFriendly = false,
    int petCount = 0,
    Map<String, dynamic>? addons,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
    String? pickupLat,
    String? pickupLng,
    String? dropLat,
    String? dropLng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('phone_number') ??
          prefs.getString('user_phone') ??
          prefs.getString('userPhone') ??
          '';
      final savedName = prefs.getString('user_name') ??
          prefs.getString('userName') ??
          '';
      final savedEmail = prefs.getString('user_email') ??
          prefs.getString('userEmail') ??
          '';

      final phone = (customerMobile != null && customerMobile.trim().isNotEmpty)
          ? customerMobile.trim()
          : (savedPhone.isNotEmpty ? savedPhone : null);
      final name = (customerName != null && customerName.trim().isNotEmpty)
          ? customerName.trim()
          : (savedName.isNotEmpty ? savedName : 'App User');
      final email = (customerEmail != null && customerEmail.trim().isNotEmpty)
          ? customerEmail.trim()
          : (savedEmail.isNotEmpty ? savedEmail : null);

      final cleanFrom = fromCity ??
          (pickupAddress.contains(',')
              ? pickupAddress.split(',')[0].trim()
              : pickupAddress);
      final cleanTo = toCity ??
          (dropAddress.contains(',')
              ? dropAddress.split(',')[0].trim()
              : dropAddress);

      // Clean distance and duration into numeric values
      double? distanceKm;
      if (distance != null && distance.isNotEmpty) {
        final numStr = distance.replaceAll(RegExp(r'[^\d.]'), '');
        distanceKm = double.tryParse(numStr);
      }

      int? durationMinutes;
      if (duration != null && duration.isNotEmpty) {
        final numStr = duration.replaceAll(RegExp(r'[^\d]'), '');
        durationMinutes = int.tryParse(numStr);
      }

      final leadBody = <String, dynamic>{
        'serviceType': serviceType,
        'tripType': wayType ?? serviceType,
        'fromCity': cleanFrom.isNotEmpty ? cleanFrom : 'Kolkata',
        if (cleanTo.isNotEmpty) 'toCity': cleanTo,
        'pickupAddress': pickupAddress,
        'dropAddress': dropAddress,
        'pickupDate':
            pickupDate ?? DateFormat('dd-MM-yyyy').format(DateTime.now()),
        'pickupTime': pickupTime ?? '10:00 AM',
        if (returnDate != null) 'returnDate': returnDate,
        if (returnTime != null) 'returnTime': returnTime,
        if (rentalPackage != null) 'hourlyPackage': rentalPackage,
        if (airportDirection != null) 'airportMode': airportDirection,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (fare != null) 'estimatedFare': fare,
        'customerName': name,
        if (phone != null && phone.isNotEmpty) 'customerMobile': phone,
        if (email != null && email.isNotEmpty) 'customerEmail': email,
        'source': 'BroomBoom App (Search Bar)',
        'rawSearchParams': {
          'vehicleCategory': vehicleCategory,
          'seater': seater,
          'petFriendly': petFriendly,
          'petCount': petCount,
          'addons': addons,
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'dropLat': dropLat,
          'dropLng': dropLng,
        },
      };

      final res = await ApiService.post('/booking-leads', leadBody);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('[BookingService] Failed to record search lead: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> calculateFare({
    required double distance,
    required String category,
    required String state,
    String? city,
  }) async {
    try {
      final response = await ApiService.post('/bookings/calculate-fare', {
        'distance': distance,
        'category': category,
        'state': state,
        'city': city,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error calculating fare: $e');
      return null;
    }
  }
}
