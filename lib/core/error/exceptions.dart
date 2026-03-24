class VaultException implements Exception {
  const VaultException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WrongPasswordException extends VaultException {
  const WrongPasswordException(super.message);
}

class FileCorruptedException extends VaultException {
  const FileCorruptedException(super.message);
}
