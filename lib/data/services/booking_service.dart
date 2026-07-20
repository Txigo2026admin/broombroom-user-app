import 'dart:convert';
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
      final response = await ApiService.post('/bookings', booking.toJson());
      if (response.statusCode == 201) {
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
