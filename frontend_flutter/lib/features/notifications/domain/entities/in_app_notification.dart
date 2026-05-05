import 'package:isar/isar.dart';

part 'in_app_notification.g.dart';

@collection
class InAppNotification {
  Id id = Isar.autoIncrement; // Isar auto-increment ID
  
  late String uuid;           // UUID único para sincronização (future-proof)
  late String leadId;         // FK para deep link
  
  @enumerated
  late NotificationType type; // enum: novo_lead, lead_qualificado, agendamento...
  
  late String title;          // ex: "Novo Lead Qualificado"
  late String body;           // corpo completo da notificação
  late bool read;             // true = usuário viu, false = não viu
  late DateTime receivedAt;   // quando chegou
  
  String? actionUrl;          // deep link gerado: /leads/lead-001, /agenda/2026-05-15
  String? leadName;           // denormalizado para UI (nome do cliente)
  String? leadPhone;          // denormalizado para UI (WhatsApp)
  
  // Índices para queries eficientes
  @Index()
  late DateTime receivedAtIndex; // para ordenação DESC
  
  @Index()
  late bool readIndex;           // para filtro "não lidas"
  
  @Index()
  late String leadIdIndex;       // para agregar por lead

  @Index(unique: true)
  late String uuidIndex;         // para busca rápida por UUID
  
  // Construtor
  InAppNotification({
    required this.uuid,
    required this.leadId,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    required this.receivedAt,
    this.actionUrl,
    this.leadName,
    this.leadPhone,
  }) {
    receivedAtIndex = receivedAt;
    readIndex = read;
    leadIdIndex = leadId;
    uuidIndex = uuid;
  }
  
  // Default constructor for Isar
  InAppNotification.isar();
}

// Enum de tipos de notificação
enum NotificationType {
  novoLead('Novo Lead'),
  leadQualificado('Lead Qualificado'),
  agendamentoConfirmado('Agendamento Confirmado'),
  leadInativo('Lead Inativo — Atenção'),
  propostaEnviada('Proposta Enviada'),
  propostaAprovada('Proposta Aprovada'),
  sistemaAlerta('Alerta do Sistema');
  
  final String label;
  const NotificationType(this.label);
}
