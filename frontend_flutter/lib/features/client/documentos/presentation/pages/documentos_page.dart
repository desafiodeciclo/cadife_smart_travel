import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/widgets.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageScaffold(
      title: 'Documentos',
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 72),
            // Principais Documentos Section
            Padding(
              padding: const EdgeInsets.all(12),
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
                          child: isSelected
                              ? ShadButton(
                                  onPressed: () {
                                    setState(() => _selectedCategory = category);
                                  },
                                  size: ShadButtonSize.sm,
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  decoration: ShadDecoration(
                                    border: ShadBorder.all(
                                      color: isDark ? Colors.white : Colors.black,
                                      radius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(category),
                                )
                              : ShadButton.outline(
                                  onPressed: () {
                                    setState(() => _selectedCategory = category);
                                  },
                                  size: ShadButtonSize.sm,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                  decoration: ShadDecoration(
                                    border: ShadBorder.all(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                      radius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(category),
                                ),
                        );
                      }).toList(),
                    ),
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
                      final filteredDocs = _selectedCategory == 'Todos'
                          ? docs
                          : docs
                                .where((d) => d.category == _selectedCategory)
                                .toList();

                      if (filteredDocs.isEmpty && _selectedCategory != 'Todos') {
                        return const AppEmptyState(type: EmptyType.emptySearch);
                      }

                      return Column(
                        children: filteredDocs
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key < filteredDocs.length - 1 ? 12 : 0,
                                ),
                                child: CadifeDocumentCard(
                                  document: entry.value,
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
                              ),
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
                          .map(
                            (trip) => TripSelectionCard(
                              trip: trip,
                              onTap: () {
                                context.push(
                                  '/client/documents/${trip.id}',
                                );
                              },
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
