class GlobalSetting {
  final String id;
  final String key;
  final dynamic value;

  GlobalSetting({
    required this.id,
    required this.key,
    required this.value,
  });

  factory GlobalSetting.fromJson(Map<String, dynamic> json) {
    return GlobalSetting(
      id: json['_id'] ?? '',
      key: json['key'] ?? '',
      value: json['value'],
    );
  }
}
