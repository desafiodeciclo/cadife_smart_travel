
import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/widgets/cadife_app_bar.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentosPage extends ConsumerStatefulWidget {
  const DocumentosPage({super.key});

  @override
  ConsumerState<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends ConsumerState<DocumentosPage> {
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final globalDocsAsync = ref.watch(globalDocumentsProvider);
    final tripsWithDocsAsync = ref.watch(tripsWithDocumentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CadifeAppBar(title: 'Documentos'),
          // Principais Documentos Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Principais Documentos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filter bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Todos',
                        'Roteiro',
                        'Voucher',
                        'Seguro',
                        'Passagens',
                        'Geral',
                      ].map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = category);
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : null,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  globalDocsAsync.when(
                    loading: () => Column(
                      children: List.generate(3, (index) => const DocumentCardSkeleton()),
                    ),
                    error: (e, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erro ao carregar documentos',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    data: (docs) {
                      final filteredDocs = _selectedCategory == 'Todos'
                          ? docs
                          : docs.where((d) => d.category == _selectedCategory).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum documento disponível ainda. Seu consultor irá compartilhá-los em breve.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Nenhum documento nesta categoria.',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: filteredDocs
                            .map(
                              (doc) => CadifeDocumentCard(
                                document: doc,
                                onView: () {
                                  context.push('/client/documentos/viewer', extra: doc);
                                },
                                onDownload: () {
                                  // Navigating to viewer also allows download
                                  context.push('/client/documentos/viewer', extra: doc);
                                },
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Documentos por Viagem Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos por Viagem',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  tripsWithDocsAsync.when(
                    loading: () => Column(
                      children: List.generate(2, (index) => const DocumentCardSkeleton()),
                    ),
                    error: (e, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erro ao carregar viagens',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    data: (trips) => trips.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Nenhuma viagem com documentos',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: trips
                                .map(
                                  (trip) => TripSelectionCard(
                                    trip: trip,
                                    onTap: () {
                                      context.push('/client/documentos/${trip.id}');
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
