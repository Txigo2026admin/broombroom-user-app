import 'dart:convert';
import '../models/airport.dart';
import 'api_service.dart';

class AirportService {
  static final List<Airport> _fallbackAirports = [
    Airport(
      id: 'default-ccu',
      name: 'Netaji Subhash Chandra Bose International Airport',
      code: 'CCU',
      city: 'Kolkata',
      state: 'West Bengal',
      lat: 22.6547,
      lon: 88.4467,
      terminals: ['Terminal 1 (Domestic)', 'Terminal 2 (International)'],
    ),
    Airport(
      id: 'default-del',
      name: 'Indira Gandhi International Airport',
      code: 'DEL',
      city: 'Delhi',
      state: 'Delhi',
      lat: 28.5562,
      lon: 77.1000,
      terminals: ['Terminal 1 (T1)', 'Terminal 2 (T2)', 'Terminal 3 (T3)'],
    ),
    Airport(
      id: 'default-bom',
      name: 'Chhatrapati Shivaji Maharaj International Airport',
      code: 'BOM',
      city: 'Mumbai',
      state: 'Maharashtra',
      lat: 19.0896,
      lon: 72.8656,
      terminals: ['Terminal 1 (T1 - Domestic)', 'Terminal 2 (T2 - International & Domestic)'],
    ),
    Airport(
      id: 'default-blr',
      name: 'Kempegowda International Airport',
      code: 'BLR',
      city: 'Bengaluru',
      state: 'Karnataka',
      lat: 13.1986,
      lon: 77.7066,
      terminals: ['Terminal 1 (T1)', 'Terminal 2 (T2)'],
    ),
    Airport(
      id: 'default-hyd',
      name: 'Rajiv Gandhi International Airport',
      code: 'HYD',
      city: 'Hyderabad',
      state: 'Telangana',
      lat: 17.2403,
      lon: 78.4294,
      terminals: ['Main Terminal (Domestic & International)'],
    ),
    Airport(
      id: 'default-maa',
      name: 'Chennai International Airport',
      code: 'MAA',
      city: 'Chennai',
      state: 'Tamil Nadu',
      lat: 12.9941,
      lon: 80.1709,
      terminals: ['Terminal 1 (Domestic)', 'Terminal 2 (International)', 'Terminal 4 (Domestic)'],
    ),
    Airport(
      id: 'default-amd',
      name: 'Sardar Vallabhbhai Patel International Airport',
      code: 'AMD',
      city: 'Ahmedabad',
      state: 'Gujarat',
      lat: 23.0772,
      lon: 72.6347,
      terminals: ['Terminal 1 (Domestic)', 'Terminal 2 (International)'],
    ),
    Airport(
      id: 'default-ixb',
      name: 'Bagdogra Airport',
      code: 'IXB',
      city: 'Siliguri',
      state: 'West Bengal',
      lat: 26.6812,
      lon: 88.3286,
      terminals: ['Terminal 1'],
    ),
    Airport(
      id: 'default-rdp',
      name: 'Kazi Nazrul Islam Airport',
      code: 'RDP',
      city: 'Durgapur',
      state: 'West Bengal',
      lat: 23.6231,
      lon: 87.2423,
      terminals: ['Passenger Terminal'],
    ),
  ];

  static Future<List<Airport>> getAirports() async {
    try {
      final response = await ApiService.get('/airports');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((item) => Airport.fromJson(item)).toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      print('[AirportService] Error fetching airports from backend: $e');
    }
    return _fallbackAirports;
  }
}

