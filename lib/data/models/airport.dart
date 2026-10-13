class Airport {
  final String id;
  final String name;
  final String code;
  final String city;
  final String? state;
  final double? lat;
  final double? lon;
  final List<String> terminals;
  final String status;

  Airport({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    this.state,
    this.lat,
    this.lon,
    this.terminals = const [],
    this.status = 'Active',
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    List<String> parsedTerminals = [];
    if (json['terminals'] is List) {
      parsedTerminals = (json['terminals'] as List)
          .map((t) => t.toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    double? parseCoord(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return Airport(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      lat: parseCoord(json['lat']),
      lon: parseCoord(json['lon'] ?? json['lng']),
      terminals: parsedTerminals,
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'city': city,
      'state': state,
      'lat': lat,
      'lon': lon,
      'terminals': terminals,
      'status': status,
    };
  }
}

