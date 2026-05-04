import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

/// Fixtures são os dados de teste usados em toda a suíte.
/// Evitam que cada teste construa seus próprios modelos inline e garantem consistência.
class LeadFixture {
  static Lead quente() => Lead(
        id: 'lead-001',
        name: 'João Silva',
        phone: '+5511999887766',
        status: LeadStatus.qualificado,
        score: LeadScore.quente,
        completudePct: 85,
        destino: 'Paris, França',
        dataIda: DateTime(2026, 12, 15),
        dataVolta: DateTime(2026, 12, 22),
        numPessoas: 2,
        createdAt: DateTime(2026, 5, 1),
      );

  static Lead frio() => Lead(
        id: 'lead-002',
        name: 'Maria Souza',
        phone: '+5521988776655',
        status: LeadStatus.novo,
        score: LeadScore.frio,
        completudePct: 25,
        createdAt: DateTime(2026, 4, 28),
      );
}

class BriefingFixture {
  static Briefing completo() => Briefing(
        leadId: 'lead-001',
        completudePct: 100,
        destino: 'Paris, França',
        dataIda: DateTime(2026, 12, 15),
        dataVolta: DateTime(2026, 12, 22),
        numPessoas: 2,
        perfil: 'Casal em lua de mel',
        tipoViagem: 'Luxo',
        preferencias: 'Gastronomia, Museus',
        orcamentoFaixa: '20k-30k',
        passaporteValido: true,
        experienciaInternacional: true,
      );
}

class ProposalFixture {
  static Proposta rascunho() => Proposta(
        id: 'prop-001',
        leadId: 'lead-001',
        consultorId: 'cons-001',
        status: ProposalStatus.rascunho,
        totalValue: 25000.0,
        destino: 'Paris, França',
        createdAt: DateTime(2026, 5, 2),
      );
}

class UserFixture {
  static AuthUser consultor() => AuthUser(
        id: 'cons-001',
        email: 'consultor@cadife.com',
        name: 'Carlos Consultor',
        role: UserRole.consultor,
        createdAt: DateTime(2026, 1, 1),
      );
}
