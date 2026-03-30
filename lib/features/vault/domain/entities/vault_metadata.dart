class VaultMetadata {
  const VaultMetadata({
    required this.name,
    required this.hint,
    required this.createdAt,
  });

  final String name;
  final String hint;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hint': hint,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory VaultMetadata.fromJson(Map<String, dynamic> json) {
    return VaultMetadata(
      name: json['name'] as String? ?? 'Vault',
      hint: json['hint'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
