abstract class EncryptionService {
  const EncryptionService();

  /// Encrypts plaintext using a password-derived key.
  ///
  /// The returned payload is self-contained (salt + nonce + ciphertext + MAC)
  /// encoded as a single string so callers can store it as-is.
  Future<String> encrypt(String plainText, String password);

  /// Decrypts a payload produced by [encrypt].
  Future<String> decrypt(String cipherText, String password);
}
