import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:cadife_smart_travel/main_common.dart';

void main() async {
  await initializeApp(AppConfig.prod, const CadifeAppWrapper());
}
