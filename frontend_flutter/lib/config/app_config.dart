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
  
  // Override opcional via build:
  //   flutter build apk --dart-define=API_BASE_URL=https://...
  // Se a flag não for passada, cada flavor usa sua URL padrão (defaultValue).
  static const AppConfig dev = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://lab.alphaedtech.org.br/server12', // Use 'adb reverse tcp:8080 tcp:8080' para celular físico via USB
    ),
    firebaseProjectId: 'cadife-dev-123',
    enableDebugLogs: true,
    appName: 'Cadife Dev',
    versionName: '1.0.0-dev',
  );

  static const AppConfig staging = AppConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://lab.alphaedtech.org.br/server12',
    ),
    firebaseProjectId: 'cadife-staging-456',
    enableDebugLogs: true,
    appName: 'Cadife Staging',
    versionName: '1.0.0-staging',
  );

  static const AppConfig prod = AppConfig(
    environment: AppEnvironment.prod,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://lab.alphaedtech.org.br/server12',
    ),
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
