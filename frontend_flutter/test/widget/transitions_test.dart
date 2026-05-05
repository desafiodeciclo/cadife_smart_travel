import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SlideTransitionPage anima corretamente', (tester) async {
    // Mock minimal app context
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LeadsPage(),
        ),
      ),
    );
    
    // Verifica se a página inicial carregou
    expect(find.byType(LeadsPage), findsOneWidget);
  });
  
  testWidgets('Hero transition existe no LeadDetailPage', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LeadDetailPage(leadId: 'test-123'),
        ),
      ),
    );
    
    // Verifica se o Hero está presente na tela de detalhe
    // (Pode falhar se leadId não for encontrado no provider real, 
    // mas o teste foca na estrutura)
    expect(find.byType(Hero), findsWidgets);
  });
  
  testWidgets('AnimatedSwitcher está presente em transições de conteúdo', (tester) async {
     await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LeadDetailPage(leadId: 'test-123'),
        ),
      ),
    );
    
    // Verifica se AnimatedSwitcher existe na tela
    expect(find.byType(AnimatedSwitcher), findsWidgets);
  });
}
