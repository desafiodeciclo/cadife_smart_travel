import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';

class MockAdminRepository {
  final List<ConsultorAdmin> _consultores = [
    const ConsultorAdmin(
      id: 'c1',
      name: 'Jakeline Lima',
      email: 'jakeline@cadifetour.com.br',
      phone: '+55 11 99999-1111',
      isActive: true,
      leadsAtivos: 12,
      taxaConversao: 0.78,
      avatarUrl: 'https://i.pravatar.cc/150?u=jakeline',
      totalLeadsAtendidos: 45,
      receitaGerada: 1250000.0,
    ),
    const ConsultorAdmin(
      id: 'c2',
      name: 'Diego Costa',
      email: 'diego@cadifetour.com.br',
      phone: '+55 11 98888-2222',
      isActive: true,
      leadsAtivos: 8,
      taxaConversao: 0.65,
      avatarUrl: 'https://i.pravatar.cc/150?u=diego',
      totalLeadsAtendidos: 32,
      receitaGerada: 890000.0,
    ),
    const ConsultorAdmin(
      id: 'c3',
      name: 'Otávio Grotto',
      email: 'otavio@cadifetour.com.br',
      phone: '+55 11 97777-3333',
      isActive: false,
      leadsAtivos: 0,
      taxaConversao: 0.42,
      avatarUrl: 'https://i.pravatar.cc/150?u=otavio',
      totalLeadsAtendidos: 18,
      receitaGerada: 320000.0,
    ),
    const ConsultorAdmin(
      id: 'c4',
      name: 'Nikolas Tesch',
      email: 'nikolas@cadifetour.com.br',
      phone: '+55 11 96666-4444',
      isActive: true,
      leadsAtivos: 5,
      taxaConversao: 0.71,
      avatarUrl: 'https://i.pravatar.cc/150?u=nikolas',
      totalLeadsAtendidos: 28,
      receitaGerada: 760000.0,
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

    final mediaTaxaConversao = _consultores.isEmpty ? 0.0 : somaTaxaConversao / _consultores.length;

    return AgenciaMetrics(
      totalLeads: totalLeadsAtivos,
      taxaConversao: mediaTaxaConversao,
      receitaEstimada: totalReceita,
      consultoresAtivos: consultoresAtivos,
      leadsNovosMes: 23, // Mantendo estático ou poderia ser calculado
      leadsFechadosMes: totalLeadsAtendidos,
      leadsPerdidosMes: 4,
    );
  }
}
