import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AddonItem {
  final String id;
  final String key;
  final String name;
  final double price;
  final String description;
  final bool isActive;
  final bool isPopular;

  const AddonItem({
    required this.id,
    required this.key,
    required this.name,
    required this.price,
    this.description = '',
    this.isActive = true,
    this.isPopular = false,
  });

  bool get isPetAddon =>
      key.toLowerCase().contains('pet') ||
      id.toLowerCase().contains('pet') ||
      name.toLowerCase().contains('pet');

  factory AddonItem.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final double parsedPrice =
        rawPrice is num
            ? rawPrice.toDouble()
            : (double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0);

    final name = (json['name'] ?? '').toString().trim();
    final key =
        (json['key'] ?? '').toString().trim().isNotEmpty
            ? json['key'].toString().trim()
            : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    return AddonItem(
      id: (json['id'] ?? key).toString(),
      key: key,
      name: name.isNotEmpty ? name : 'Add-on Service',
      price: parsedPrice,
      description: (json['description'] ?? '').toString().trim(),
      isActive: json['isActive'] != false,
      isPopular: json['isPopular'] == true,
    );
  }
}

class AddonService {
  static const List<AddonItem> defaultAddons = [
    AddonItem(
      id: 'addon-pet',
      key: 'petAllowance',
      name: 'Travel with Pet (Pet Allowance)',
      price: 1001,
      description: 'Sanitized pet-friendly cab with protective seat covers',
    ),
    AddonItem(
      id: 'addon-carrier',
      key: 'roofCarrier',
      name: 'Add Roof Carrier',
      price: 157,
      description: 'Fit 4 more large bags comfortably on luggage carrier',
    ),
    AddonItem(
      id: 'addon-lang',
      key: 'language',
      name: 'Preferred Driver Language',
      price: 209,
      description: 'Assigns driver fluent in English, Hindi, or Bengali',
    ),
    AddonItem(
      id: 'addon-new-vehicle',
      key: 'newVehicle',
      name: 'New Vehicle (2023+)',
      price: 262,
      description: 'Promised latest 2023 or newer car model with pristine interior',
    ),
    AddonItem(
      id: 'addon-sightseeing',
      key: 'sightseeing',
      name: 'Local sightseeing package',
      price: 787,
      description: 'Dedicated sightseeing route stopovers within city limits',
    ),
    AddonItem(
      id: 'addon-refundable',
      key: 'refundable',
      name: 'Upgrade to Refundable booking',
      price: 751,
      description: '100% refund for cancellation before 3 hours of departure time',
    ),
  ];

  /// Fetches addon services configured in Admin via GET /api/addons
  static Future<List<AddonItem>> getAddons() async {
    try {
      final response = await ApiService.get('/addons');
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['addons'] is List) {
            rawList = decoded['addons'] as List;
          } else if (decoded['data'] is List) {
            rawList = decoded['data'] as List;
          }
        }

        final parsed =
            rawList
                .whereType<Map<String, dynamic>>()
                .map(AddonItem.fromJson)
                .where((a) => a.isActive)
                .toList();

        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AddonService] Error fetching addons: $e');
      }
    }
    return List<AddonItem>.from(defaultAddons);
  }
}
