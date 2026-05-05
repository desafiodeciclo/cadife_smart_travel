import 'package:flutter_test/flutter_test.dart';
import 'package:cadife_smart_travel/config/app_config.dart';

void main() {
  test('AppConfig.dev aponta para localhost', () {
    expect(AppConfig.dev.apiBaseUrl, contains('localhost'));
    expect(AppConfig.dev.environment, AppEnvironment.dev);
  });
  
  test('AppConfig.staging aponta para staging-api', () {
    expect(AppConfig.staging.apiBaseUrl, contains('staging-api'));
  });
  
  test('AppConfig.prod aponta para api.cadife.com', () {
    expect(AppConfig.prod.apiBaseUrl, contains('api.cadife.com'));
    expect(AppConfig.prod.enableDebugLogs, isFalse);
  });
  
  test('AppConfig.fromEnvironment detecta ambientes', () {
    expect(AppConfig.fromEnvironment('dev'), equals(AppConfig.dev));
    expect(AppConfig.fromEnvironment('staging'), equals(AppConfig.staging));
    expect(AppConfig.fromEnvironment('prod'), equals(AppConfig.prod));
  });
}
