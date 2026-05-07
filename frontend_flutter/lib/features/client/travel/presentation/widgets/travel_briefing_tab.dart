import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:cadife_smart_travel/features/client/travel/domain/entities/briefing_flag.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/providers/client_briefing_notifier.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/widgets/briefing_data_card.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/widgets/briefing_section.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/widgets/briefing_status_timeline.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/widgets/pending_info_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class TravelBriefingTab extends ConsumerWidget {
  const TravelBriefingTab({required this.leadId, super.key});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(clientBriefingProvider(leadId));

    return briefingAsync.when(
      loading: () => const _BriefingShimmer(),
      error: (e, _) => _BriefingError(onRetry: () => ref.read(clientBriefingProvider(leadId).notifier).refresh()),
      data: (viewState) => _BriefingContent(
        leadId: leadId,
        viewState: viewState,
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _BriefingContent extends ConsumerWidget {
  const _BriefingContent({required this.leadId, required this.viewState});

  final String leadId;
  final BriefingViewState viewState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = viewState.briefing;
    final flags = ref.watch(briefingFlagProvider(leadId));
    final flagNotifier = ref.read(briefingFlagProvider(leadId).notifier);

    // Derive status for timeline from completude
    final travelStatus = _statusFromCompletude(briefing.completudePct);

    // Derive pending fields
    final pendingFields = _buildPendingFields(briefing);

    void onFlag(String field, BriefingFlagType type) {
      final current = flagNotifier.flagFor(field);
      if (current == type) {
        flagNotifier.removeFlag(field);
      } else {
        flagNotifier.addFlag(field, type);
        if (type == BriefingFlagType.incorreto) {
          _showIncorretoModal(context, field);
        }
      }
    }

    BriefingFlagType? flagFor(String field) =>
        flags.cast<BriefingFlag?>().firstWhere(
              (f) => f?.field == field,
              orElse: () => null,
            )?.type;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Offline banner
        if (viewState.isOffline)
          SliverToBoxAdapter(
            child: _OfflineBanner(cachedAt: viewState.cachedAt),
          ),

        // Completude progress
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _CompletudeBar(pct: briefing.completudePct),
          ),
        ),

        // ── Section 1: Viagem ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: BriefingSection(
            title: 'Viagem',
            icon: LucideIcons.plane,
            initiallyExpanded: true,
            children: [
              BriefingDataCard(
                fieldKey: 'destino',
                label: 'Destino',
                value: briefing.destino,
                currentFlag: flagFor('destino'),
                onFlag: (t) => onFlag('destino', t),
              ),
              BriefingDataCard(
                fieldKey: 'data_ida',
                label: 'Data de Partida',
                value: briefing.dataIda != null
                    ? DateFormat('dd/MM/yyyy').format(briefing.dataIda!)
                    : null,
                currentFlag: flagFor('data_ida'),
                onFlag: (t) => onFlag('data_ida', t),
              ),
              BriefingDataCard(
                fieldKey: 'data_volta',
                label: 'Data de Retorno',
                value: briefing.dataVolta != null
                    ? DateFormat('dd/MM/yyyy').format(briefing.dataVolta!)
                    : null,
                currentFlag: flagFor('data_volta'),
                onFlag: (t) => onFlag('data_volta', t),
              ),
              if (briefing.dataIda != null && briefing.dataVolta != null)
                BriefingDataCard(
                  fieldKey: 'duracao',
                  label: 'Duração',
                  value: '${briefing.dataVolta!.difference(briefing.dataIda!).inDays} dias',
                ),
              BriefingDataCard(
                fieldKey: 'tipo_viagem',
                label: 'Tipo de Viagem',
                value: briefing.tipoViagem,
                currentFlag: flagFor('tipo_viagem'),
                onFlag: (t) => onFlag('tipo_viagem', t),
              ),
            ],
          ),
        ),

        // ── Section 2: Passageiros ────────────────────────────────────────
        SliverToBoxAdapter(
          child: BriefingSection(
            title: 'Passageiros',
            icon: LucideIcons.users,
            children: [
              BriefingDataCard(
                fieldKey: 'num_pessoas',
                label: 'Total de Passageiros',
                value: briefing.numPessoas?.toString(),
                currentFlag: flagFor('num_pessoas'),
                onFlag: (t) => onFlag('num_pessoas', t),
              ),
              BriefingDataCard(
                fieldKey: 'perfil',
                label: 'Perfil do Grupo',
                value: briefing.perfil,
                currentFlag: flagFor('perfil'),
                onFlag: (t) => onFlag('perfil', t),
              ),
              BriefingDataCard(
                fieldKey: 'passaporte_valido',
                label: 'Passaporte Válido',
                value: briefing.passaporteValido == null
                    ? null
                    : briefing.passaporteValido!
                        ? 'Sim'
                        : 'Não',
                currentFlag: flagFor('passaporte_valido'),
                onFlag: (t) => onFlag('passaporte_valido', t),
              ),
              BriefingDataCard(
                fieldKey: 'experiencia_internacional',
                label: 'Experiência Internacional',
                value: briefing.experienciaInternacional == null
                    ? null
                    : briefing.experienciaInternacional!
                        ? 'Sim'
                        : 'Não',
                currentFlag: flagFor('experiencia_internacional'),
                onFlag: (t) => onFlag('experiencia_internacional', t),
              ),
            ],
          ),
        ),

        // ── Section 3: Orçamento ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: BriefingSection(
            title: 'Orçamento',
            icon: LucideIcons.wallet,
            children: [
              BriefingDataCard(
                fieldKey: 'orcamento_faixa',
                label: 'Faixa de Orçamento',
                value: briefing.orcamentoFaixa,
                currentFlag: flagFor('orcamento_faixa'),
                onFlag: (t) => onFlag('orcamento_faixa', t),
              ),
              if (briefing.orcamentoFaixa != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OrcamentoBar(faixa: briefing.orcamentoFaixa!),
                ),
            ],
          ),
        ),

        // ── Section 4: Preferências ───────────────────────────────────────
        SliverToBoxAdapter(
          child: BriefingSection(
            title: 'Preferências',
            icon: LucideIcons.star,
            children: [
              BriefingDataCard(
                fieldKey: 'preferencias',
                label: 'Preferências Especiais',
                value: briefing.preferencias,
                currentFlag: flagFor('preferencias'),
                onFlag: (t) => onFlag('preferencias', t),
              ),
              if (briefing.resumoConversa != null)
                BriefingDataCard(
                  fieldKey: 'resumo_conversa',
                  label: 'Resumo da Conversa',
                  value: briefing.resumoConversa,
                ),
            ],
          ),
        ),

        // ── Section 5: Timeline de Status ─────────────────────────────────
        SliverToBoxAdapter(
          child: BriefingSection(
            title: 'Status do Atendimento',
            icon: LucideIcons.clock,
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: BriefingStatusTimeline(status: travelStatus),
              ),
            ],
          ),
        ),

        // ── Section 6: Informações Pendentes ──────────────────────────────
        if (pendingFields.isNotEmpty)
          SliverToBoxAdapter(
            child: BriefingSection(
              title: 'Informações Pendentes',
              icon: LucideIcons.circleAlert,
              itemCount: pendingFields.length,
              children: [
                PendingInfoList(pendingFields: pendingFields),
              ],
            ),
          ),

        // ── Bottom action ──────────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: _ContactButton(leadId: leadId),
          ),
        ),
      ],
    );
  }

  TravelStatus _statusFromCompletude(int pct) {
    if (pct >= 80) return TravelStatus.qualificado;
    if (pct >= 60) return TravelStatus.emAtendimento;
    return TravelStatus.emAtendimento;
  }

  List<String> _buildPendingFields(Briefing briefing) {
    final missing = <String>[];
    if (briefing.destino == null || briefing.destino!.isEmpty) missing.add('Destino');
    if (briefing.dataIda == null) missing.add('Data de partida');
    if (briefing.dataVolta == null) missing.add('Data de retorno');
    if (briefing.numPessoas == null) missing.add('Número de passageiros');
    if (briefing.orcamentoFaixa == null) missing.add('Faixa de orçamento');
    if (briefing.tipoViagem == null) missing.add('Tipo de viagem');
    return missing;
  }

  Future<void> _showIncorretoModal(BuildContext context, String field) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IncorretoModal(fieldName: field),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.cachedAt});
  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final timeAgo = cachedAt != null
        ? 'Atualizado ${_formatTimeAgo(cachedAt!)}'
        : 'Dados locais';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 14, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo offline — $timeAgo',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    return 'há ${diff.inHours}h';
  }
}

class _CompletudeBar extends StatelessWidget {
  const _CompletudeBar({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final color = pct >= 80
        ? cadife.success
        : pct >= 60
            ? AppColors.warning
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'COMPLETUDE DO BRIEFING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: cadife.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: cadife.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _OrcamentoBar extends StatelessWidget {
  const _OrcamentoBar({required this.faixa});
  final String faixa;

  static const _tiers = ['10k-20k', '20k-35k', '35k-60k', '60k-100k', '100k+'];

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final idx = _tiers.indexWhere(
      (t) => faixa.toLowerCase().contains(t.split('-').first.toLowerCase()),
    );
    final filled = idx < 0 ? 2 : idx + 1;

    return Row(
      children: List.generate(
        5,
        (i) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 6,
            decoration: BoxDecoration(
              color: i < filled
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : cadife.cardBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.leadId});
  final String leadId;

  static const _cadifeWhatsapp = '5511999999999';

  Future<void> _openWhatsApp(BuildContext context) async {
    const msg = 'Olá! Gostaria de corrigir algumas informações do meu briefing de viagem.';
    final uri = Uri.parse(
      'https://wa.me/$_cadifeWhatsapp?text=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return OutlinedButton.icon(
      onPressed: () => _openWhatsApp(context),
      icon: const Icon(LucideIcons.messageCircle, size: 16),
      label: const Text('Informação incorreta? Fale com a AYA'),
      style: OutlinedButton.styleFrom(
        foregroundColor: cadife.textSecondary,
        side: BorderSide(color: cadife.cardBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _IncorretoModal extends StatelessWidget {
  const _IncorretoModal({required this.fieldName});
  final String fieldName;

  static const _cadifeWhatsapp = '5511999999999';

  Future<void> _openWhatsApp(BuildContext context) async {
    final msg = 'Olá! A informação "$fieldName" no meu briefing está incorreta. '
        'Pode me ajudar a corrigir?';
    final uri = Uri.parse(
      'https://wa.me/$_cadifeWhatsapp?text=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: cadife.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cadife.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageCircle, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'Informação incorreta?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cadife.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deseja entrar em contato com a AYA para corrigir "$fieldName"?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cadife.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(context),
              icon: const Icon(LucideIcons.messageCircle, size: 18),
              label: const Text('Abrir WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: cadife.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _BriefingError extends StatelessWidget {
  const _BriefingError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: cadife.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o briefing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cadife.textSecondary),
            ),
            const SizedBox(height: 20),
            ShadButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _BriefingShimmer extends StatelessWidget {
  const _BriefingShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Completude bar skeleton
          const Skeleton(height: 44, borderRadius: 8),
          const SizedBox(height: 12),
          // Section skeletons
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: const Skeleton(height: 72, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }
}
