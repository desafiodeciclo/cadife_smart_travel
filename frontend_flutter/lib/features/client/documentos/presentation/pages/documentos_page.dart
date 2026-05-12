import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/widgets.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
enum DocumentTypeFilter { all, pdf, image }
enum DocumentOriginFilter { all, global, perTrip }

class DocumentosPage extends ConsumerStatefulWidget {
  const DocumentosPage({super.key});

  @override
  ConsumerState<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends ConsumerState<DocumentosPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DocumentTypeFilter _typeFilter = DocumentTypeFilter.all;
  DocumentOriginFilter _originFilter = DocumentOriginFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Documento> _applyFilters(List<Documento> docs) {
    var filtered = docs;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((d) => d.name.toLowerCase().contains(q)).toList();
    }

    // Type filter
    if (_typeFilter != DocumentTypeFilter.all) {
      filtered = filtered.where((d) {
        if (_typeFilter == DocumentTypeFilter.pdf) {
          return d.type == DocumentType.pdf;
        }
        if (_typeFilter == DocumentTypeFilter.image) {
          return d.type == DocumentType.image;
        }
        return true;
      }).toList();
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
                          _typeFilter = DocumentTypeFilter.all;
                          _originFilter = DocumentOriginFilter.all;
                        });
                        setModalState(() {
                          _typeFilter = DocumentTypeFilter.all;
                          _originFilter = DocumentOriginFilter.all;
                        });
                      },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'TIPO DE ARQUIVO',
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
                      value: DocumentTypeFilter.all,
                      groupValue: _typeFilter,
                      onChanged: (v) {
                        setModalState(() => _typeFilter = v);
                        setState(() => _typeFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'PDF',
                      value: DocumentTypeFilter.pdf,
                      groupValue: _typeFilter,
                      onChanged: (v) {
                        setModalState(() => _typeFilter = v);
                        setState(() => _typeFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Imagens',
                      value: DocumentTypeFilter.image,
                      groupValue: _typeFilter,
                      onChanged: (v) {
                        setModalState(() => _typeFilter = v);
                        setState(() => _typeFilter = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'ORIGEM',
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
                      value: DocumentOriginFilter.all,
                      groupValue: _originFilter,
                      onChanged: (v) {
                        setModalState(() => _originFilter = v);
                        setState(() => _originFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Principais',
                      value: DocumentOriginFilter.global,
                      groupValue: _originFilter,
                      onChanged: (v) {
                        setModalState(() => _originFilter = v);
                        setState(() => _originFilter = v);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Por Viagem',
                      value: DocumentOriginFilter.perTrip,
                      groupValue: _originFilter,
                      onChanged: (v) {
                        setModalState(() => _originFilter = v);
                        setState(() => _originFilter = v);
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
    final globalDocsAsync = ref.watch(globalDocumentsProvider);
    final tripsWithDocsAsync = ref.watch(tripsWithDocumentsProvider);

    return PageScaffold(
      title: 'Documentos',
      actions: const [NotificationBell(), SizedBox(width: 8)],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShadInput(
                controller: _searchController,
                placeholder: const Text('Buscar documento...'),
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
                          color: context.isDark ? Colors.white60 : context.cadife.textSecondary,
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
            // Principais Documentos Section
            if (_originFilter == DocumentOriginFilter.all ||
                _originFilter == DocumentOriginFilter.global)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PRINCIPAIS DOCUMENTOS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StateContainer(
                      state: globalDocsAsync,
                      onRetry: () => ref.refresh(globalDocumentsProvider),
                      loadingWidget: Column(
                        children: List.generate(
                          3,
                          (index) => const DocumentCardSkeleton(),
                        ),
                      ),
                      isEmpty: globalDocsAsync.valueOrNull?.isEmpty ?? false,
                      customEmptyType: EmptyType.noDocuments,
                      dataBuilder: (docs) {
                        final filteredDocs = _applyFilters(docs);

                        if (filteredDocs.isEmpty) {
                          return const AppEmptyState(
                              type: EmptyType.emptySearch);
                        }

                        return Column(
                          children: filteredDocs
                              .asMap()
                              .entries
                              .expand(
                                (entry) => [
                                  CadifeDocumentCard(
                                    document: entry.value,
                                    padding: EdgeInsets.zero,
                                    onView: () {
                                      context.push(
                                        '/client/documents/viewer',
                                        extra: entry.value,
                                      );
                                    },
                                    onDownload: () {
                                      context.push(
                                        '/client/documents/viewer',
                                        extra: entry.value,
                                      );
                                    },
                                  ),
                                  if (entry.key < filteredDocs.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Documentos por Viagem Section
            if (_originFilter == DocumentOriginFilter.all ||
                _originFilter == DocumentOriginFilter.perTrip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOCUMENTOS POR VIAGEM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StateContainer(
                      state: tripsWithDocsAsync,
                      onRetry: () => ref.refresh(tripsWithDocumentsProvider),
                      loadingWidget: Column(
                        children: List.generate(
                          2,
                          (index) => const DocumentCardSkeleton(),
                        ),
                      ),
                      isEmpty: tripsWithDocsAsync.valueOrNull?.isEmpty ?? false,
                      customEmptyType: EmptyType.emptyList,
                      dataBuilder: (trips) => Column(
                        children: trips
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key < trips.length - 1 ? 10 : 0,
                                ),
                                child: TripSelectionCard(
                                  trip: entry.value,
                                  onTap: () {
                                    context.push(
                                      '/client/documents/${entry.value.id}',
                                    );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
