import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'location_service.dart';

class DistanceService {
  static const String osrmUrl = 'https://router.project-osrm.org/route/v1/driving';

  static Future<double> getDistance(
    String from,
    String to, {
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) async {
    // 1. Check via backend map API first (fast, DB cached, avoids Android cleartext/CORS blocks)
    try {
      final body = <String, dynamic>{
        'from': from,
        'to': to,
      };
      if (pickupLat != null) body['pickupLat'] = pickupLat;
      if (pickupLng != null) body['pickupLng'] = pickupLng;
      if (dropLat != null) body['dropLat'] = dropLat;
      if (dropLng != null) body['dropLng'] = dropLng;

      final response = await ApiService.post('/pricing-rules/distance', body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['distance'] != null) {
          final dist = (data['distance'] as num).toDouble();
          if (dist > 0) return dist;
        }
      }
    } catch (e) {
      print('Backend distance check notice: $e');
    }

    // 2. Direct HTTPS OSRM fallback
    try {
      double? lat1 = pickupLat;
      double? lon1 = pickupLng;
      double? lat2 = dropLat;
      double? lon2 = dropLng;

      if (lat1 == null || lon1 == null) {
        final fromData = await LocationService.searchCities(from);
        if (fromData.isNotEmpty) {
          lat1 = double.tryParse(fromData[0]['lat']?.toString() ?? '');
          lon1 = double.tryParse((fromData[0]['lon'] ?? fromData[0]['lng'])?.toString() ?? '');
        }
      }

      if (lat2 == null || lon2 == null) {
        final toData = await LocationService.searchCities(to);
        if (toData.isNotEmpty) {
          lat2 = double.tryParse(toData[0]['lat']?.toString() ?? '');
          lon2 = double.tryParse((toData[0]['lon'] ?? toData[0]['lng'])?.toString() ?? '');
        }
      }

      if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return 0.0;

      final response = await http.get(
        Uri.parse('$osrmUrl/$lon1,$lat1;$lon2,$lat2?overview=false'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final distMeters = (data['routes'][0]['distance'] as num).toDouble();
          return ((distMeters / 1000.0) * 10).round() / 10.0;
        }
      }
      return 0.0;
    } catch (e) {
      print('Error calculating OSRM distance: $e');
      return 0.0;
    }
  }
}
