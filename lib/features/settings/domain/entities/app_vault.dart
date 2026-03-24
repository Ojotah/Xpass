class AppVault {
  const AppVault({
    required this.id,
    required this.name,
    required this.passwordHint,
  });

  final String id;
  final String name;
  final String passwordHint;

  AppVault copyWith({
    String? id,
    String? name,
    String? passwordHint,
  }) {
    return AppVault(
      id: id ?? this.id,
      name: name ?? this.name,
      passwordHint: passwordHint ?? this.passwordHint,
    );
  }
}
