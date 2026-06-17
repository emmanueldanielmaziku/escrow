class ProviderModel {
  final String id;
  final String name;
  final String code;
  final String type;
  final Map<String, dynamic>? metadata;

  ProviderModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.metadata,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      type: map['type'] as String,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}
