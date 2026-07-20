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
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      seater: json['seater'] ?? 0,
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      perKmRate: (json['perKmRate'] ?? 0).toDouble(),
      status: json['status'] ?? 'Inactive',
    );
  }
}
