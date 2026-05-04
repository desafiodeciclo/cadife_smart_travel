import 'package:alchemist/alchemist.dart';
import 'package:cadife_smart_travel/design_system/components/cadife_button.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadifeButton Golden Tests', () {
    goldenTest(
      'renderiza corretamente em diferentes estados',
      fileName: 'cadife_button',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Primary',
            child: const CadifeButton(text: 'Botão Principal'),
          ),
          GoldenTestScenario(
            name: 'Outline',
            child: const CadifeButton(text: 'Botão Outline', isOutline: true),
          ),
          GoldenTestScenario(
            name: 'Loading',
            child: const CadifeButton(text: 'Carregando', isLoading: true),
          ),
          GoldenTestScenario(
            name: 'Disabled',
            child: const CadifeButton(text: 'Desabilitado', onPressed: null),
          ),
        ],
      ),
    );
  });
}
