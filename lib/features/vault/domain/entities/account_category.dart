enum AccountCategory {
  all,
  microsoft,
  google,
  apple,
  others,
}

extension AccountCategoryLabel on AccountCategory {
  String get label {
    return switch (this) {
      AccountCategory.all => 'All',
      AccountCategory.microsoft => 'Microsoft',
      AccountCategory.google => 'Google',
      AccountCategory.apple => 'Apple',
      AccountCategory.others => 'Others',
    };
  }
}
