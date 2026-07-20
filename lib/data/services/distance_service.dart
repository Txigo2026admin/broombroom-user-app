import 'dart:convert';
import 'package:http/http.dart' as http;
import 'location_service.dart';

class DistanceService {
  static const String osrmUrl = 'http://router.project-osrm.org/route/v1/driving';

  static Future<double> getDistance(String from, String to) async {
    try {
      final fromData = await LocationService.searchCities(from);
      final toData = await LocationService.searchCities(to);

      if (fromData.isEmpty || toData.isEmpty) return 0.0;

      final lat1 = fromData[0]['lat'];
      final lon1 = fromData[0]['lon'];
      final lat2 = toData[0]['lat'];
      final lon2 = toData[0]['lon'];

      final response = await http.get(
        Uri.parse('$osrmUrl/$lon1,$lat1;$lon2,$lat2?overview=false'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // Distance is in meters, convert to km
          return (data['routes'][0]['distance'] / 1000.0);
        }
      }
      
      // Fallback to simple estimation if OSRM fails
      return 0.0;
    } catch (e) {
      print('Error calculating OSRM distance: $e');
      return 0.0;
    }
  }
}
