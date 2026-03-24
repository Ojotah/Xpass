class Account {
  const Account({
    required this.title,
    required this.username,
    required this.password,
    this.note = '',
  });

  final String title;
  final String username;
  final String password;
  final String note;
}
