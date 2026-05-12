import 'package:equatable/equatable.dart';

class ConversationSummaryTopics extends Equatable {
  final String? intencaoPrincipal;
  final String? datasEPassageiros;
  final String? orcamento;
  final String? restricoesEPreferencias;
  final String? decisoesTomadas;
  final String? proximosPassos;

  const ConversationSummaryTopics({
    this.intencaoPrincipal,
    this.datasEPassageiros,
    this.orcamento,
    this.restricoesEPreferencias,
    this.decisoesTomadas,
    this.proximosPassos,
  });

  @override
  List<Object?> get props => [
        intencaoPrincipal,
        datasEPassageiros,
        orcamento,
        restricoesEPreferencias,
        decisoesTomadas,
        proximosPassos,
      ];
}

class ConversationSummary extends Equatable {
  final String id;
  final String leadId;
  final String sessaoId;
  final ConversationSummaryTopics? resumo;
  final bool resumoPendente;
  final DateTime geradoEm;
  final int? tokensUtilizados;

  const ConversationSummary({
    required this.id,
    required this.leadId,
    required this.sessaoId,
    required this.resumoPendente,
    required this.geradoEm,
    this.resumo,
    this.tokensUtilizados,
  });

  @override
  List<Object?> get props => [id, leadId, sessaoId, resumoPendente, geradoEm];
}
