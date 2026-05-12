import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/cadife_document_card.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:cadife_smart_travel/features/client/home/infrastructure/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_day.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/trip_status_section.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/itinerary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local view-model — normalises ClientTrip / TripSummary into one shape
// ─────────────────────────────────────────────────────────────────────────────

class _VM {
  const _VM({
    required this.id,
    this.name,
    this.destination,
    this.destinationCountry,
    this.flag,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    this.status,
    this.progressPercentage,
    this.checkpoints,
    this.roteiro,
  });

  final String id;
  final String? name;
  final String? destination;
  final String? destinationCountry;
  final String? flag;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String? status;
  final double? progressPercentage;
  final List<TripCheckpoint>? checkpoints;
  final String? roteiro;

  String get displayTitle => flag != null && destination != null
      ? '$flag $destination'
      : name ?? destination ?? 'Viagem';

  factory _VM.fromClientTrip(ClientTrip t) => _VM(
        id: t.id,
        name: t.destination,
        destination: t.destination,
        destinationCountry: t.destinationCountry,
        flag: t.destinationFlag,
        startDate: t.startDate,
        endDate: t.endDate,
        coverImageUrl: t.coverImageUrl,
        status: t.status,
        progressPercentage: t.progressPercentage,
        checkpoints: t.checkpoints,
        roteiro: t.roteiro,
      );

  factory _VM.fromSummary(TripSummary t) => _VM(
        id: t.id,
        name: t.name,
        destination: t.destino,
        startDate: t.dataIda,
        endDate: t.dataVolta,
        coverImageUrl: t.imageUrl,
        status: 'concluido',
        roteiro: t.roteiro,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point — resolves which data source to use
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current trip is a mock — resolve synchronously with no loading state
    final currentTrip = ClientHomeMocks.mockCurrentTrip();
    if (currentTrip.id == tripId) {
      return _DetailView(
        vm: _VM.fromClientTrip(currentTrip),
        clientTrip: currentTrip,
      );
    }

    // Otherwise look up in the travel history provider
    return ref.watch(travelHistoryProvider).when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro ao carregar: $e')),
      ),
      data: (trips) {
        final summary = trips.where((t) => t.id == tripId).firstOrNull;
        if (summary == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Viagem não encontrada')),
          );
        }
        return _DetailView(vm: _VM.fromSummary(summary));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified detail view — renders the same layout for both trip types
// ─────────────────────────────────────────────────────────────────────────────

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.vm, this.clientTrip});

  final _VM vm;

  // Non-null only when viewing the active trip (enables full status section)
  final ClientTrip? clientTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;
    final itState = ref.watch(itineraryProvider(vm.id));
    final docsAsync = ref.watch(tripDocumentsProvider(vm.id));

    final days = itState.itemsByDay.entries
        .map((e) => ItineraryDay(data: e.key, itens: e.value))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final fmt = DateFormat('dd/MM/yy', 'pt_BR');
    final dateRange = vm.startDate != null && vm.endDate != null
        ? '${fmt.format(vm.startDate!)} → ${fmt.format(vm.endDate!)}'
        : '—';
    final durationDays = vm.startDate != null && vm.endDate != null
        ? vm.endDate!.difference(vm.startDate!).inDays
        : null;

    return Scaffold(
        backgroundColor: cadife.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── [A] Hero cover image ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: AppColors.overlayMedium,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/client/status');
                      }
                    },
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: _CoverImage(vm: vm),
              ),
            ),

            // ── [B] Content ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: cadife.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination title
                    Text(
                      vm.displayTitle,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cadife.textPrimary,
                      ),
                    ),
                    if (vm.destinationCountry != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 13, color: cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            vm.destinationCountry!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: cadife.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── [1] Dates + Duration ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _InfoBadge(
                            icon: LucideIcons.calendar,
                            label: 'Período',
                            value: dateRange,
                            onTap: () => context.push('/client/travel/${vm.id}/calendar'),
                          ),
                        ),
                        if (durationDays != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoBadge(
                              icon: LucideIcons.clock,
                              label: 'Duração',
                              value: '$durationDays dias',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── [2] Status section ────────────────────────────────
                    if (clientTrip != null) ...[
                      TripStatusSection(trip: clientTrip!),
                      const SizedBox(height: 28),
                    ] else ...[
                      _SimpleStatusRow(status: vm.status ?? 'concluido'),
                      const SizedBox(height: 28),
                    ],

                    // ── [3] Full itinerary ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ITINERÁRIO',
                          style: TextStyle(
                            color: cadife.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/client/travel/${vm.id}/calendar'),
                          child: Text(
                            'Ver calendário',
                            style: TextStyle(
                              color: cadife.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (itState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (days.isEmpty)
                      const _EmptyCard(label: 'Itinerário ainda não disponível')
                    else
                      ItineraryWidget(days: days, isCompact: false),
                    const SizedBox(height: 32),

                    // ── [4] Documents ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DOCUMENTOS',
                          style: TextStyle(
                            color: cadife.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/client/documents/${vm.id}'),
                          child: Text(
                            'Ver todos',
                            style: TextStyle(
                              color: cadife.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    docsAsync.when(
                      data: (docs) => docs.isEmpty
                          ? const _EmptyCard(label: 'Nenhum documento disponível')
                          : SizedBox(
                              height: 130,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                physics: const BouncingScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (_, i) {
                                  final doc = docs[i];
                                  return SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.85,
                                    child: CadifeDocumentCard(
                                      document: doc,
                                      onView: () => context.push(
                                        '/client/documentos/viewer',
                                        extra: doc,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    // ── [5] Quick access — Diary + Suitcase ───────────────
                    Text(
                      'ACESSO RÁPIDO',
                      style: TextStyle(
                        color: cadife.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessCard(
                            icon: LucideIcons.bookOpen,
                            label: 'Diário de\nViagem',
                            accentColor: const Color(0xFF4F46E5),
                            onTap: () => context.push('/client/profile/diary/${vm.id}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAccessCard(
                            icon: LucideIcons.briefcase,
                            label: 'Minha\nMala',
                            accentColor: const Color(0xFF0D9488),
                            onTap: () => context.go('/client/profile?tab=2'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.vm});

  final _VM vm;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    Widget image;
    if (vm.coverImageUrl != null) {
      image = Hero(
        tag: 'trip_banner_${vm.id}',
        child: Image.network(
          vm.coverImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.zinc800,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.white.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => _PlaceholderCover(cadife: cadife),
        ),
      );
    } else {
      image = _PlaceholderCover(cadife: cadife);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // Gradient overlay so back button stays visible
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.cadife});

  final CadifeThemeExtension cadife;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.zinc800,
      child: Center(
        child: Icon(
          LucideIcons.plane,
          size: 64,
          color: AppColors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return GestureDetector(
      onTap: onTap,
      child: CadifeCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cadife.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cadife.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: cadife.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cadife.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 16, color: cadife.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SimpleStatusRow extends StatelessWidget {
  const _SimpleStatusRow({required this.status});

  final String status;

  String get _label => switch (status) {
        'planejando' => 'Planejando',
        'confirmado' => 'Confirmado',
        'em_andamento' => 'Em Andamento',
        'concluido' => 'Concluída',
        _ => status,
      };

  Color get _color => switch (status) {
        'planejando' => Colors.blue,
        'confirmado' => AppColors.success,
        'em_andamento' => AppColors.warning,
        'concluido' => Colors.purple,
        _ => AppColors.zinc500,
      };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'STATUS DA VIAGEM',
          style: TextStyle(
            color: cadife.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cadife.muted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cadife.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cadife.textSecondary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return CadifeCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Acessar',
                style: AppTextStyles.caption.copyWith(color: accentColor),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 11, color: accentColor),
            ],
          ),
        ],
      ),
    );
  }
}
