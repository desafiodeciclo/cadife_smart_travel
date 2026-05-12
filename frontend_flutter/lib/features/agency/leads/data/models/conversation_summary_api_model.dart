import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';

class ConversationSummaryTopicsApiModel {
  final String? intencaoPrincipal;
  final String? datasEPassageiros;
  final String? orcamento;
  final String? restricoesEPreferencias;
  final String? decisoesTomadas;
  final String? proximosPassos;

  const ConversationSummaryTopicsApiModel({
    this.intencaoPrincipal,
    this.datasEPassageiros,
    this.orcamento,
    this.restricoesEPreferencias,
    this.decisoesTomadas,
    this.proximosPassos,
  });

  factory ConversationSummaryTopicsApiModel.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryTopicsApiModel(
      intencaoPrincipal: json['intencao_principal'] as String?,
      datasEPassageiros: json['datas_e_passageiros'] as String?,
      orcamento: json['orcamento'] as String?,
      restricoesEPreferencias: json['restricoes_e_preferencias'] as String?,
      decisoesTomadas: json['decisoes_tomadas'] as String?,
      proximosPassos: json['proximos_passos'] as String?,
    );
  }

  ConversationSummaryTopics toDomain() => ConversationSummaryTopics(
        intencaoPrincipal: intencaoPrincipal,
        datasEPassageiros: datasEPassageiros,
        orcamento: orcamento,
        restricoesEPreferencias: restricoesEPreferencias,
        decisoesTomadas: decisoesTomadas,
        proximosPassos: proximosPassos,
      );
}

class ConversationSummaryApiModel {
  final String id;
  final String leadId;
  final String sessaoId;
  final ConversationSummaryTopicsApiModel? resumoJson;
  final bool resumoPendente;
  final DateTime geradoEm;
  final int? tokensUtilizados;

  const ConversationSummaryApiModel({
    required this.id,
    required this.leadId,
    required this.sessaoId,
    required this.resumoPendente,
    required this.geradoEm,
    this.resumoJson,
    this.tokensUtilizados,
  });

  factory ConversationSummaryApiModel.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['resumo_json'];
    return ConversationSummaryApiModel(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      sessaoId: json['sessao_id'] as String,
      resumoPendente: json['resumo_pendente'] as bool,
      geradoEm: DateTime.parse(json['gerado_em'] as String),
      resumoJson: rawTopics != null
          ? ConversationSummaryTopicsApiModel.fromJson(
              rawTopics as Map<String, dynamic>)
          : null,
      tokensUtilizados: json['tokens_utilizados'] as int?,
    );
  }

  ConversationSummary toDomain() => ConversationSummary(
        id: id,
        leadId: leadId,
        sessaoId: sessaoId,
        resumoPendente: resumoPendente,
        geradoEm: geradoEm,
        resumo: resumoJson?.toDomain(),
        tokensUtilizados: tokensUtilizados,
      );
}
