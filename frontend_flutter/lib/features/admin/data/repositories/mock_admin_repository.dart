import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';

/// Dados alinhados com backend/scripts/db/seeds/01_users.py e 02_leads.py
class MockAdminRepository {
  final List<ConsultorAdmin> _consultores = [
    const ConsultorAdmin(
      id: 'daniela-costa',
      name: 'Daniela Costa',
      email: 'daniela.costa@cadifetoure.com.br',
      phone: '+55 11 97777-7777',
      isActive: true,
      leadsAtivos: 2,
      taxaConversao: 0.75,
      avatarUrl: 'https://i.pravatar.cc/150?u=daniela',
      totalLeadsAtendidos: 42,
      receitaGerada: 1480000.0,
    ),
    const ConsultorAdmin(
      id: 'jakeline-lima',
      name: 'Jakeline Lima',
      email: 'jakeline.lima@cadifetoure.com.br',
      phone: '+55 11 99999-1111',
      isActive: true,
      leadsAtivos: 2,
      taxaConversao: 0.68,
      avatarUrl: 'https://i.pravatar.cc/150?u=jakeline',
      totalLeadsAtendidos: 35,
      receitaGerada: 980000.0,
    ),
    const ConsultorAdmin(
      id: 'diego-costa',
      name: 'Diego Costa',
      email: 'diego.costa@cadifetoure.com.br',
      phone: '+55 11 98888-2222',
      isActive: true,
      leadsAtivos: 2,
      taxaConversao: 0.62,
      avatarUrl: 'https://i.pravatar.cc/150?u=diego',
      totalLeadsAtendidos: 28,
      receitaGerada: 740000.0,
    ),
    const ConsultorAdmin(
      id: 'marcos-andrade',
      name: 'Marcos Andrade',
      email: 'marcos.andrade@cadifetoure.com.br',
      phone: '+55 11 97777-3333',
      isActive: false,
      leadsAtivos: 1,
      taxaConversao: 0.45,
      avatarUrl: 'https://i.pravatar.cc/150?u=marcos',
      totalLeadsAtendidos: 16,
      receitaGerada: 310000.0,
    ),
  ];

  Future<List<ConsultorAdmin>> getConsultores() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_consultores);
  }

  Future<ConsultorAdmin?> getConsultorById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _consultores.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  Future<ConsultorAdmin> toggleConsultorStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _consultores.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('Consultor não encontrado');
    final updated = _consultores[index].copyWith(isActive: !_consultores[index].isActive);
    _consultores[index] = updated;
    return updated;
  }

  Future<ConsultorAdmin> createConsultor({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final newConsultor = ConsultorAdmin(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      isActive: true,
      leadsAtivos: 0,
      taxaConversao: 0.0,
    );
    _consultores.add(newConsultor);
    return newConsultor;
  }

  Future<ConsultorAdmin> updateConsultor(ConsultorAdmin consultor) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _consultores.indexWhere((c) => c.id == consultor.id);
    if (index == -1) throw Exception('Consultor não encontrado');
    _consultores[index] = consultor;
    return consultor;
  }

  Future<void> deleteConsultor(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _consultores.removeWhere((c) => c.id == id);
  }

  Future<AgenciaMetrics> getMetrics() async {
    await Future.delayed(const Duration(milliseconds: 500));

    int totalLeadsAtivos = 0;
    int totalLeadsAtendidos = 0;
    double totalReceita = 0;
    double somaTaxaConversao = 0;
    int consultoresAtivos = 0;

    for (final c in _consultores) {
      totalLeadsAtivos += c.leadsAtivos;
      totalLeadsAtendidos += c.totalLeadsAtendidos ?? 0;
      totalReceita += c.receitaGerada ?? 0;
      somaTaxaConversao += c.taxaConversao;
      if (c.isActive) consultoresAtivos++;
    }

    final mediaTaxaConversao =
        _consultores.isEmpty ? 0.0 : somaTaxaConversao / _consultores.length;

    return AgenciaMetrics(
      totalLeads: totalLeadsAtivos,
      taxaConversao: mediaTaxaConversao,
      receitaEstimada: totalReceita,
      consultoresAtivos: consultoresAtivos,
      leadsNovosMes: 7,
      leadsFechadosMes: totalLeadsAtendidos,
      leadsPerdidosMes: 3,
    );
  }
}
