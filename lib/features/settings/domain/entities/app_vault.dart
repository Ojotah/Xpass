class AppVault {
  const AppVault({
    required this.id,
    required this.name,
    required this.passwordHint,
    required this.createdAt,
    required this.fileName,
  });

  final String id;
  final String name;
  final String passwordHint;
  final DateTime createdAt;
  final String fileName;

  AppVault copyWith({
    String? id,
    String? name,
    String? passwordHint,
    DateTime? createdAt,
    String? fileName,
  }) {
    return AppVault(
      id: id ?? this.id,
      name: name ?? this.name,
      passwordHint: passwordHint ?? this.passwordHint,
      createdAt: createdAt ?? this.createdAt,
      fileName: fileName ?? this.fileName,
    );
  }
}
