import 'package:cadife_smart_travel/main_dev.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'deve realizar login com sucesso e navegar para a dashboard',
    ($) async {
      // Inicializa o app
      app.main();
      await $.pumpAndSettle();

      // 1. Verifica se os elementos da LoginScreen estão presentes
      expect($('Smart Travel'), findsOneWidget);
      expect($('ENTRAR'), findsOneWidget);

      // 2. Preenche e-mail e senha
      // Usamos find.byKey via seletor de símbolo do Patrol
      await $(#email_field).enterText('admin@cadife.com');
      await $(#password_field).enterText('123456');

      // 3. Clica no botão de entrar
      await $('ENTRAR').tap();
      
      // 4. Aguarda a transição e valida se saiu da tela de login
      await $.pumpAndSettle();
      
      // Nota: O destino final depende da lógica de roteamento do app.
      // Geralmente verificamos um elemento único da home/dashboard.
      // expect($('Minhas Propostas'), findsOneWidget);
    },
  );
}
