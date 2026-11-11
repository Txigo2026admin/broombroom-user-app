import 'dart:convert';
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

  /// Records any user search inquiry as an instant Booking Lead in admin with source 'BroomBoom App'
  static Future<Booking?> recordSearchLead({
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
    String? pickupLat,
    String? pickupLng,
    String? dropLat,
    String? dropLng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('phone_number') ?? prefs.getString('user_phone') ?? '';
      final savedName = prefs.getString('user_name') ?? 'App Customer';

      final phone = (customerMobile != null && customerMobile.trim().isNotEmpty)
          ? customerMobile.trim()
          : (savedPhone.isNotEmpty ? savedPhone : '9876543210');
      final name = (customerName != null && customerName.trim().isNotEmpty)
          ? customerName.trim()
          : savedName;

      final body = {
        'customerName': name,
        'customerMobile': phone,
        'serviceType': serviceType,
        'wayType': wayType ?? 'One Way',
        'airportDirection': airportDirection,
        'airportTerminal': airportTerminal,
        'rentalPackage': rentalPackage,
        'state': 'West Bengal',
        'pickupAddress': pickupAddress,
        'dropAddress': dropAddress,
        'fromCity': fromCity ?? (pickupAddress.contains(',') ? pickupAddress.split(',')[0].trim() : pickupAddress),
        'toCity': toCity ?? (dropAddress.contains(',') ? dropAddress.split(',')[0].trim() : dropAddress),
        'distance': distance,
        'duration': duration,
        'pickupDate': pickupDate ?? DateTime.now().toIso8601String().split('T')[0],
        'pickupTime': pickupTime ?? '10:00 AM',
        'returnDate': returnDate,
        'returnTime': returnTime,
        'vehicleCategory': vehicleCategory ?? 'Sedan',
        'seater': seater ?? 4,
        'fare': fare ?? 0,
        'status': 'Pending',
        'paymentStatus': 'PENDING',
        'source': 'BroomBoom App',
        'petFriendly': petFriendly,
        'petCount': petCount,
        'addons': addons ?? (petFriendly ? {'petAllowance': true, 'petCount': petCount} : {}),
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
      };

      final res = await ApiService.post('/bookings', body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Booking.fromJson(jsonDecode(res.body));
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
