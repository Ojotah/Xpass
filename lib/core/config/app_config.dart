class AppConfig {
  const AppConfig._();

  static const breachApiBaseUrl = String.fromEnvironment(
    'BREACH_API_BASE_URL',
    defaultValue: 'https://api.pwnedpasswords.com/range/',
  );

  static const breachDetectionEnabled = bool.fromEnvironment(
    'FEATURE_BREACH_DETECTION',
    defaultValue: true,
  );
}
