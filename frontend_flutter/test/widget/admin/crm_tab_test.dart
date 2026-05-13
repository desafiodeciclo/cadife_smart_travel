import 'package:cadife_smart_travel/models/lead.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:cadife_smart_travel/screens/admin/crm_tab.dart';
import 'package:cadife_smart_travel/widgets/lead_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class MockLeadsNotifier extends AsyncNotifier<LeadsListResponse> with Mock implements LeadsNotifier {}

void main() {
  late LeadsListResponse mockResponse;

  setUp(() {
    mockResponse = LeadsListResponse(
      items: [
        Lead(
          id: '1',
          nome: 'Teste Lead 1',
          telefone: '11999999999',
          status: 'novo',
          score: 85.5,
          criadoEm: DateTime.now(),
        ),
      ],
      total: 1,
      page: 1,
      pages: 1,
    );
  });

  testWidgets('Deve exibir CircularProgressIndicator enquanto carrega', (tester) async {
    // Para testar o estado de loading, usamos um stream que não completa imediatamente
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leadsProvider.overrideWith(() => _LoadingNotifier()),
        ],
        child: const MaterialApp(home: CrmTab()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Deve renderizar lista de leads quando houver dados', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leadsProvider.overrideWith(() => _DataNotifier(mockResponse)),
        ],
        child: const MaterialApp(home: CrmTab()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LeadCard), findsOneWidget);
    expect(find.text('Teste Lead 1'), findsOneWidget);
    expect(find.text('Score: 85.5'), findsOneWidget);
  });

  testWidgets('Botões de paginação devem respeitar os limites', (tester) async {
    final multiPageResponse = LeadsListResponse(
      items: [],
      total: 20,
      page: 1,
      pages: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leadsProvider.overrideWith(() => _DataNotifier(multiPageResponse)),
        ],
        child: const MaterialApp(home: CrmTab()),
      ),
    );

    await tester.pumpAndSettle();

    // Página 1: Anterior deve estar desabilitado (onPressed is null)
    final anteriorFinder = find.widgetWithText(TextButton, 'Anterior');
    final anteriorBtn = tester.widget<TextButton>(anteriorFinder);
    expect(anteriorBtn.onPressed, isNull);

    // Página 1: Próximo deve estar habilitado
    final proximoFinder = find.widgetWithText(ElevatedButton, 'Próximo');
    final proximoBtn = tester.widget<ElevatedButton>(proximoFinder);
    expect(proximoBtn.onPressed, isNotNull);
  });
}

class _LoadingNotifier extends LeadsNotifier {
  @override
  Future<LeadsListResponse> build() => Future.any([]);
}

class _DataNotifier extends LeadsNotifier {
  final LeadsListResponse data;
  _DataNotifier(this.data);
  @override
  Future<LeadsListResponse> build() async => data;
}
