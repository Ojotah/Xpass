import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.title,
    required super.username,
    required super.password,
  });

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      title: account.title,
      username: account.username,
      password: account.password,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'username': username,
        'password': password,
      };
}
