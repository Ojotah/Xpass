import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.title,
    required super.username,
    required super.password,
    super.note,
    super.isCompromised,
  });

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      title: account.title,
      username: account.username,
      password: account.password,
      note: account.note,
      isCompromised: account.isCompromised,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      note: json['note'] as String? ?? '',
      isCompromised: json['isCompromised'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'username': username,
        'password': password,
        'note': note,
        'isCompromised': isCompromised,
      };
}
