import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class LocationService {
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<List<Map<String, dynamic>>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$nominatimUrl?q=$query&format=json&addressdetails=1&limit=5&countrycodes=in'),
        headers: {'User-Agent': 'BroomBoomUserApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error searching cities: $e');
    }
    return [];
  }

  static Future<void> saveCityToBackend(Map<String, dynamic> cityData) async {
    try {
      final body = {
        'name': cityData['name'] ?? cityData['display_name'].split(',')[0],
        'displayName': cityData['display_name'],
        'lat': cityData['lat'],
        'lon': cityData['lon'],
        'state': cityData['address']?['state'] ?? '',
        'country': cityData['address']?['country'] ?? 'India',
        'placeId': cityData['place_id'].toString(),
      };

      await ApiService.post('/cities', body);
    } catch (e) {
      print('Error saving city to backend: $e');
    }
  }
}
