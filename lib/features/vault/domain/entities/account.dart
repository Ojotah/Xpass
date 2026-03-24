class Account {
  const Account({
    required this.title,
    required this.username,
    required this.password,
    this.note = '',
    this.isCompromised = false,
  });

  final String title;
  final String username;
  final String password;
  final String note;
  final bool isCompromised;

  Account copyWith({
    String? title,
    String? username,
    String? password,
    String? note,
    bool? isCompromised,
  }) {
    return Account(
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      isCompromised: isCompromised ?? this.isCompromised,
    );
  }
}
