import 'dart:convert';
import '../models/car_category.dart';
import 'api_service.dart';

class CarService {
  static Future<List<CarCategory>> getCarCategories() async {
    try {
      final response = await ApiService.get('/car-categories');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CarCategory.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load car categories');
      }
    } catch (e) {
      print('Error fetching car categories: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> calculatePrice({
    required String rideType,
    required String sourceCity,
    required String destinationCity,
    required String category,
    required double distance,
    double? oneWayDistance,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    int? days,
    String? state,
    int? packageHours,
    int? includedKms,
    String? petType,
    bool? carryingPet,
    Map<String, dynamic>? addons,
  }) async {
    try {
      final body = <String, dynamic>{
        'rideType': rideType,
        'sourceCity': sourceCity,
        'destinationCity': destinationCity,
        'category': category,
        'distance': distance,
        'days': days ?? 1,
        'state': state ?? '',
      };
      if (oneWayDistance != null) body['oneWayDistance'] = oneWayDistance;
      if (pickupLat != null) body['pickupLat'] = pickupLat;
      if (pickupLng != null) body['pickupLng'] = pickupLng;
      if (dropLat != null) body['dropLat'] = dropLat;
      if (dropLng != null) body['dropLng'] = dropLng;
      if (packageHours != null) body['packageHours'] = packageHours;
      if (includedKms != null) body['includedKms'] = includedKms;
      if (petType != null) body['petType'] = petType;
      if (carryingPet != null) body['carryingPet'] = carryingPet;
      if (addons != null) body['addons'] = addons;

      final response = await ApiService.post('/pricing-rules/calculate', body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error calculating price: $e');
      return {};
    }
  }
}
