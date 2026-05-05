import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper para carregar fontes para os testes de golden.
/// Como o projeto usa GoogleFonts, é necessário carregar os arquivos .ttf manualmente se quiser fidelidade total.
Future<void> loadGoldenFonts() async {
  // Exemplo de como carregar fontes se estivessem nos assets:
  /*
  final fontLoader = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await fontLoader.load();
  */
}

/// Representação de um dispositivo para testes de golden no Cadife.
class CadifeTestDevice {
  final String name;
  final Size size;
  final double devicePixelRatio;

  const CadifeTestDevice({
    required this.name,
    required this.size,
    this.devicePixelRatio = 1.0,
  });

  BoxConstraints get constraints => BoxConstraints.tight(size);
}

/// Configurações de dispositivos comuns para testes de golden.
const deviceConfigs = [
  CadifeTestDevice(name: 'iphone_se', size: Size(375, 667), devicePixelRatio: 2.0),
  CadifeTestDevice(name: 'iphone_14', size: Size(390, 844), devicePixelRatio: 3.0),
  CadifeTestDevice(name: 'pixel_5', size: Size(393, 851), devicePixelRatio: 2.75),
];
