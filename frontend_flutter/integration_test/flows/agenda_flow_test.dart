import 'package:cadife_smart_travel/main_dev.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'Fluxo de Agenda: Deve navegar, trocar visualização e abrir modal de novo agendamento',
    ($) async {
      // 1. Inicializa o app
      app.main();
      await $.pumpAndSettle();

      // 2. Login (Assume estado inicial ou realiza login rápido)
      // Se já estiver logado (mock), pula para navegação
      if ($('ENTRAR').exists) {
        await $(#email_field).enterText('consultor@cadife.com');
        await $(#password_field).enterText('123456');
        await $('ENTRAR').tap();
        await $.pumpAndSettle();
      }

      // 3. Navegação para Agenda (Via Bottom Navigation)
      // Nota: O ícone da agenda deve ser identificável por ícone ou label
      await $(Icons.calendar_today).tap();
      await $.pumpAndSettle();

      // 4. Valida se está na tela de Agenda
      expect($('AGENDA'), findsOneWidget);

      // 5. Troca de visualização (Mês -> Dia)
      expect($('Mês'), findsOneWidget);
      await $('Dia').tap();
      await $.pumpAndSettle();

      // 6. Abre modal de novo agendamento (FAB)
      expect($('Nova reunião'), findsOneWidget);
      await $('Nova reunião').tap();
      await $.pumpAndSettle();

      // 7. Valida se o modal de seleção de lead abriu
      expect($('Selecionar Lead'), findsOneWidget);
      
      // 8. Seleciona o primeiro lead da lista (mock)
      // Assumindo que a lista de leads no modal tem itens
      await $.tester.tap(find.textContaining('Lead').first);
      await $.pumpAndSettle();

      // 9. Valida se abriu o modal de agendamento detalhado
      expect($('Agendar Reunião'), findsOneWidget);
      expect($('CONFIRMAR HORÁRIO'), findsOneWidget);

      // 10. Fecha o modal (ou cancela)
      await $.tester.pageBack();
      await $.pumpAndSettle();
    },
  );
}
