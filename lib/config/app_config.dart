/// Application configuration
/// Manages environment-specific settings like API base URLs
class AppConfig {
  // Environment detection
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // API Base URL configuration
  static const String _devBaseUrl = 'http://localhost:3000';
  static const String _stagingBaseUrl = 'https://maipay-staging.ondigitalocean.app';
  static const String _prodBaseUrl = 'https://maipay-dmrtw.ondigitalocean.app';

  /// Get the API base URL based on the current environment
  static String get baseUrl {
    switch (_environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return _devBaseUrl;
      case 'staging':
      case 'stage':
        return _stagingBaseUrl;
      case 'production':
      case 'prod':
      default:
        return _prodBaseUrl;
    }
  }

  /// Check if running in development mode
  static bool get isDevelopment => _environment.toLowerCase() == 'development' || _environment.toLowerCase() == 'dev';

  /// Check if running in production mode
  static bool get isProduction => _environment.toLowerCase() == 'production' || _environment.toLowerCase() == 'prod';

  /// Get current environment name
  static String get environment => _environment;

  /// Debug mode flag
  static bool get debugMode => !isProduction;
}



