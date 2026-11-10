import 'dart:convert';
import '../models/car_category.dart';
import 'api_service.dart';

class CarService {
  static final List<CarCategory> _fallbackCategories = [
    CarCategory(id: 'cat-sedan', name: 'Sedan', displayName: 'Sedan', seater: 4, baseFare: 50, perKmRate: 15, status: 'Active'),
    CarCategory(id: 'cat-suv', name: 'SUV', displayName: 'SUV', seater: 6, baseFare: 80, perKmRate: 19, status: 'Active'),
    CarCategory(id: 'cat-suvplus', name: 'SUV+', displayName: 'SUV+', seater: 7, baseFare: 100, perKmRate: 23, status: 'Active'),
    CarCategory(id: 'cat-traveller13', name: '13 Seater Traveller', displayName: '13 Seater Traveller', seater: 13, baseFare: 150, perKmRate: 35, status: 'Active'),
    CarCategory(id: 'cat-traveller17', name: '17 Seater Urbania', displayName: '17 Seater Urbania', seater: 17, baseFare: 180, perKmRate: 40, status: 'Active'),
    CarCategory(id: 'cat-traveller24', name: '24 Seater Urbania', displayName: '24 Seater Urbania', seater: 24, baseFare: 220, perKmRate: 45, status: 'Active'),
  ];

  static Future<List<CarCategory>> getCarCategories() async {
    try {
      final response = await ApiService.get('/car-categories');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final list = data.map((item) {
          final cat = CarCategory.fromJson(item);
          if (cat.seater == 25 || cat.name.contains('25') || cat.displayName.contains('25')) {
            return CarCategory(
              id: cat.id,
              name: cat.name.replaceAll('25', '24').replaceAll('Traveller', 'Urbania'),
              displayName: cat.displayName.replaceAll('25', '24').replaceAll('Traveller', 'Urbania'),
              seater: 24,
              baseFare: cat.baseFare,
              perKmRate: cat.perKmRate,
              status: cat.status,
            );
          }
          if (cat.seater == 17 || cat.name.contains('17') || cat.displayName.contains('17')) {
            return CarCategory(
              id: cat.id,
              name: cat.name.replaceAll('Traveller', 'Urbania'),
              displayName: cat.displayName.replaceAll('Traveller', 'Urbania'),
              seater: 17,
              baseFare: cat.baseFare,
              perKmRate: cat.perKmRate,
              status: cat.status,
            );
          }
          return cat;
        }).toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      print('Error fetching car categories: $e');
    }
    return _fallbackCategories;
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
    String? pickupDate,
    String? pickupTime,
    String? returnDate,
    String? returnTime,
    String? airportName,
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
      if (airportName != null) body['airportName'] = airportName;
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
      if (pickupDate != null) body['pickupDate'] = pickupDate;
      if (pickupTime != null) body['pickupTime'] = pickupTime;
      if (returnDate != null) body['returnDate'] = returnDate;
      if (returnTime != null) body['returnTime'] = returnTime;

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
