import 'dart:math';

class PasswordGenerator {
  const PasswordGenerator();

  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = r'!@#\$%^&*()-_=+[]{};:,.<>?';

  String generate({
    required int length,
    required bool includeUppercase,
    required bool includeLowercase,
    required bool includeNumbers,
    required bool includeSymbols,
  }) {
    final groups = <String>[
      if (includeUppercase) _upper,
      if (includeLowercase) _lower,
      if (includeNumbers) _numbers,
      if (includeSymbols) _symbols,
    ];

    if (groups.isEmpty) {
      throw ArgumentError('At least one character group must be enabled.');
    }

    final normalizedLength = length.clamp(8, 32);
    final random = Random.secure();

    final chars = <String>[
      for (final group in groups) group[random.nextInt(group.length)],
    ];

    final all = groups.join();
    for (var i = chars.length; i < normalizedLength; i++) {
      chars.add(all[random.nextInt(all.length)]);
    }

    chars.shuffle(random);
    return chars.join();
  }
}
