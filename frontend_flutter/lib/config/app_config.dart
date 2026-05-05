enum AppEnvironment { dev, staging, prod }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String firebaseProjectId;
  final bool enableDebugLogs;
  final String appName;
  final String versionName;
  
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.enableDebugLogs,
    required this.appName,
    required this.versionName,
  });
  
  // Pré-configurados
  static const AppConfig dev = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'http://localhost:4000', // ou ngrok URL via env var
    firebaseProjectId: 'cadife-dev-123',
    enableDebugLogs: true,
    appName: 'Cadife Dev',
    versionName: '1.0.0-dev',
  );
  
  static const AppConfig staging = AppConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://staging-api.cadife.com',
    firebaseProjectId: 'cadife-staging-456',
    enableDebugLogs: true,
    appName: 'Cadife Staging',
    versionName: '1.0.0-staging',
  );
  
  static const AppConfig prod = AppConfig(
    environment: AppEnvironment.prod,
    apiBaseUrl: 'https://api.cadife.com',
    firebaseProjectId: 'cadife-prod-789',
    enableDebugLogs: false,
    appName: 'Cadife',
    versionName: '1.0.0',
  );
  
  // Factory para detectar por String (usado em build time)
  factory AppConfig.fromEnvironment(String env) {
    return switch (env.toLowerCase()) {
      'dev' => AppConfig.dev,
      'staging' => AppConfig.staging,
      'prod' => AppConfig.prod,
      _ => throw ArgumentError('Unknown environment: $env'),
    };
  }
}
