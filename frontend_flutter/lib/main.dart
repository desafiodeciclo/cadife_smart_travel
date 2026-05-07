import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:cadife_smart_travel/main_common.dart';

void main() async {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await initializeApp(
    AppConfig.fromEnvironment(flavor),
    const CadifeAppWrapper(),
  );
}
