 class CarCategory {
  final String id;
  final String name;
  final String displayName;
  final int seater;
  final double baseFare;
  final double perKmRate;
  final String status;

  CarCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.seater,
    required this.baseFare,
    required this.perKmRate,
    required this.status,
  });

  factory CarCategory.fromJson(Map<String, dynamic> json) {
    return CarCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      seater: (json['seater'] is num)
          ? (json['seater'] as num).toInt()
          : (int.tryParse(json['seater']?.toString() ?? '0') ?? 0),
      baseFare: (json['baseFare'] is num)
          ? (json['baseFare'] as num).toDouble()
          : (double.tryParse(json['baseFare']?.toString() ?? '0') ?? 0.0),
      perKmRate: (json['perKmRate'] is num)
          ? (json['perKmRate'] as num).toDouble()
          : (double.tryParse(json['perKmRate']?.toString() ?? '0') ?? 0.0),
      status: json['status']?.toString() ?? 'Active',
    );
  }
}
