import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'main_common.dart';

void main() async {
  await initializeApp(AppConfig.prod);
  runApp(const CadifeAppWrapper());
}
