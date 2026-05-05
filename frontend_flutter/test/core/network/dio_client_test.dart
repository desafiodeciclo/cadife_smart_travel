import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dioClient usa baseUrl correto por config', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.dev),
      ],
    );
    
    final dio = container.read(dioClientProvider);
    expect(dio.options.baseUrl, equals(AppConfig.dev.apiBaseUrl));
  });
}
