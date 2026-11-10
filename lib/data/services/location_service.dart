import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class LocationService {
  static const String nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  static Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    // 1. Try backend search endpoint (checks DB, aliases, PIN codes, Nominatim)
    try {
      final response = await ApiService.get(
        '/cities/search?q=${Uri.encodeComponent(clean)}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            m['display_name'] = m['displayName'] ?? m['name'] ?? '';
            return m;
          }).toList();
        }
      }
    } catch (e) {
      print('Backend searchCities notice: $e');
    }

    // 2. Direct Nominatim fallback
    try {
      final isPin = RegExp(r'^[1-9][0-9]{5}$').hasMatch(clean);
      final url =
          isPin
              ? '$nominatimUrl?postalcode=${Uri.encodeComponent(clean)}&country=in&format=json&addressdetails=1&limit=6'
              : '$nominatimUrl?q=${Uri.encodeComponent(clean)}&format=json&addressdetails=1&limit=6&countrycodes=in';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BroomBoomUserApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error searching cities directly: $e');
    }
    return [];
  }

  static Future<void> saveCityToBackend(Map<String, dynamic> cityData) async {
    try {
      final body = {
        'name':
            cityData['name'] ??
            (cityData['display_name'] ?? '').toString().split(',')[0],
        'displayName':
            cityData['display_name'] ?? cityData['displayName'] ?? '',
        'lat': cityData['lat']?.toString(),
        'lon': (cityData['lon'] ?? cityData['lng'])?.toString(),
        'state': cityData['address']?['state'] ?? cityData['state'] ?? '',
        'country':
            cityData['address']?['country'] ?? cityData['country'] ?? 'India',
        'placeId':
            cityData['place_id']?.toString() ?? cityData['placeId']?.toString(),
      };

      await ApiService.post('/cities', body);
    } catch (e) {
      print('Error saving city to backend: $e');
    }
  }
}
