import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TripStatusFilter { all, completed, ongoing, upcoming }
enum PeriodFilter { all, last30Days, last6Months, lastYear }

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TripStatusFilter _statusFilter = TripStatusFilter.all;
  PeriodFilter _periodFilter = PeriodFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TripSummary> _filter(List<TripSummary> trips) {
    var filtered = trips;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.name.toLowerCase().contains(q) ||
                (t.destino?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Status filter
    final now = DateTime.now();
    if (_statusFilter != TripStatusFilter.all) {
      filtered = filtered.where((t) {
        if (t.dataIda == null || t.dataVolta == null) return true;

        switch (_statusFilter) {
          case TripStatusFilter.completed:
            return t.dataVolta!.isBefore(now);
          case TripStatusFilter.ongoing:
            return (t.dataIda!.isBefore(now) ||
                    t.dataIda!.isAtSameMomentAs(now)) &&
                (t.dataVolta!.isAfter(now) ||
                    t.dataVolta!.isAtSameMomentAs(now));
          case TripStatusFilter.upcoming:
            return t.dataIda!.isAfter(now);
          case TripStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Period filter
    if (_periodFilter != PeriodFilter.all) {
      final limitDate = switch (_periodFilter) {
        PeriodFilter.last30Days => now.subtract(const Duration(days: 30)),
        PeriodFilter.last6Months => now.subtract(const Duration(days: 180)),
        PeriodFilter.lastYear => now.subtract(const Duration(days: 365)),
        PeriodFilter.all => null,
      };

      if (limitDate != null) {
        filtered = filtered.where((t) {
          if (t.dataIda == null) return true;
          return t.dataIda!.isAfter(limitDate);
        }).toList();
      }
    }

    return filtered;
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: context.cadife.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.cadife.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filtros', style: AppTextStyles.h4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _statusFilter = TripStatusFilter.all;
                          _periodFilter = PeriodFilter.all;
                        });
                        setModalState(() {
                          _statusFilter = TripStatusFilter.all;
                          _periodFilter = PeriodFilter.all;
                        });
                      },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: context.cadife.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Todos',
                      value: TripStatusFilter.all,
                      groupValue: _statusFilter,
                      onChanged: (v) {
                        setModalState(() => _statusFilter = v);
                        setState(() => _statusFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Concluídas',
                      value: TripStatusFilter.completed,
                      groupValue: _statusFilter,
                      onChanged: (v) {
                        setModalState(() => _statusFilter = v);
                        setState(() => _statusFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Em andamento',
                      value: TripStatusFilter.ongoing,
                      groupValue: _statusFilter,
                      onChanged: (v) {
                        setModalState(() => _statusFilter = v);
                        setState(() => _statusFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Próximas',
                      value: TripStatusFilter.upcoming,
                      groupValue: _statusFilter,
                      onChanged: (v) {
                        setModalState(() => _statusFilter = v);
                        setState(() => _statusFilter = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'PERÍODO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: context.cadife.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Tudo',
                      value: PeriodFilter.all,
                      groupValue: _periodFilter,
                      onChanged: (v) {
                        setModalState(() => _periodFilter = v);
                        setState(() => _periodFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Últimos 30 dias',
                      value: PeriodFilter.last30Days,
                      groupValue: _periodFilter,
                      onChanged: (v) {
                        setModalState(() => _periodFilter = v);
                        setState(() => _periodFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Últimos 6 meses',
                      value: PeriodFilter.last6Months,
                      groupValue: _periodFilter,
                      onChanged: (v) {
                        setModalState(() => _periodFilter = v);
                        setState(() => _periodFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Último ano',
                      value: PeriodFilter.lastYear,
                      groupValue: _periodFilter,
                      onChanged: (v) {
                        setModalState(() => _periodFilter = v);
                        setState(() => _periodFilter = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ShadButton(
                  onPressed: () => context.pop(),
                  width: double.infinity,
                  child: const Text('Aplicar Filtros'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.cadife.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.cadife.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(travelHistoryProvider);

    return PageScaffold(
      title: 'Histórico',
      actions: const [NotificationBell(), SizedBox(width: 8)],
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Buscar viagem...'),
              onChanged: (v) => setState(() => _searchQuery = v),
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(LucideIcons.search, size: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty) ...[
                    ShadIconButton.ghost(
                      icon: Icon(
                        LucideIcons.x,
                        color: context.isDark
                            ? Colors.white60
                            : context.cadife.textSecondary,
                        size: 16,
                      ),
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    width: 1,
                    height: 20,
                    color: context.cadife.cardBorder,
                  ),
                  const SizedBox(width: 4),
                  ShadIconButton.ghost(
                    icon: const Icon(
                      LucideIcons.slidersHorizontal,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    onPressed: () => _showFilterOptions(context),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (trips) {
                final filtered = _filter(trips);

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    type: _searchQuery.isNotEmpty ||
                            _statusFilter != TripStatusFilter.all ||
                            _periodFilter != PeriodFilter.all
                        ? EmptyType.emptySearch
                        : EmptyType.noTrips,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(travelHistoryProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final trip = filtered[index];
                      return TripHistoryCard(
                        trip: trip,
                        onTap: () => context
                            .push('/client/travel/${trip.id}/details'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

