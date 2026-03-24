import '../../../../core/utils/password_generator.dart';

class GeneratePassword {
  const GeneratePassword(this._generator);

  final PasswordGenerator _generator;

  String call({
    required int length,
    required bool includeUppercase,
    required bool includeLowercase,
    required bool includeNumbers,
    required bool includeSymbols,
  }) {
    return _generator.generate(
      length: length,
      includeUppercase: includeUppercase,
      includeLowercase: includeLowercase,
      includeNumbers: includeNumbers,
      includeSymbols: includeSymbols,
    );
  }
}
