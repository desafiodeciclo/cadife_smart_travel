enum AppEnvironment { dev, staging, prod }

class EnvConfig {
  final String apiBaseUrl;
  final String firebaseProjectId;
  final AppEnvironment environment;

  EnvConfig({
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.environment,
  });

  static EnvConfig get dev => EnvConfig(
        apiBaseUrl: 'http://localhost:8000', // Ou IP do ngrok/máquina
        firebaseProjectId: 'cadife-smart-travel-dev',
        environment: AppEnvironment.dev,
      );

  static EnvConfig get staging => EnvConfig(
        apiBaseUrl: 'https://api-staging.cadifetravel.com', // Exemplo
        firebaseProjectId: 'cadife-smart-travel-staging',
        environment: AppEnvironment.staging,
      );

  static EnvConfig get prod => EnvConfig(
        apiBaseUrl: 'https://api.cadifetravel.com',
        firebaseProjectId: 'cadife-smart-travel-prod',
        environment: AppEnvironment.prod,
      );
}
