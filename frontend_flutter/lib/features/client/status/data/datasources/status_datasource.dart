import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';

abstract class IStatusDatasource {
  Future<Lead?> getMyStatus();
  Future<Lead?> getStatusById(String id);
}

class StatusMockDatasource implements IStatusDatasource {
  @override
  Future<Lead?> getMyStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLead('mock-lead-123');
  }

  @override
  Future<Lead?> getStatusById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLead(id);
  }

  Lead _mockLead(String id) {
    return Lead(
      id: id,
      name: 'Maria Fernanda Costa',
      email: 'maria.costa@email.com',
      phone: '+55 11 98765-4321',
      status: LeadStatus.fechado, // Representando viagem fechada/em andamento
      score: LeadScore.quente,
      completudePct: 95,
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime.now(),
      preferencias: 'Praia, Luxo, Sol',
      assignedTo: 'consultor-001',
      consultorNome: 'Jakeline Ferreira',
    );
  }
}
