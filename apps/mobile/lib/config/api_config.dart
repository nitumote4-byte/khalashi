/// Shared API base URL for AuthApi and ApiClient.
///
/// Override at build/run time with:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (local API).
/// Default points at the live Railway production API (no trailing slash).
class ApiConfig {
  ApiConfig._();

  static const productionBaseUrl =
      'https://khalashi-api-production.up.railway.app';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );
}
