class Account {
  const Account({
    required this.title,
    required this.username,
    required this.password,
    this.note = '',
    this.isCompromised = false,
    this.isWeak = false,
    this.isReused = false,
    this.riskScore = 0,
  });

  final String title;
  final String username;
  final String password;
  final String note;
  final bool isCompromised;
  final bool isWeak;
  final bool isReused;
  final int riskScore;

  Account copyWith({
    String? title,
    String? username,
    String? password,
    String? note,
    bool? isCompromised,
    bool? isWeak,
    bool? isReused,
    int? riskScore,
  }) {
    return Account(
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      isCompromised: isCompromised ?? this.isCompromised,
      isWeak: isWeak ?? this.isWeak,
      isReused: isReused ?? this.isReused,
      riskScore: riskScore ?? this.riskScore,
    );
  }
}
