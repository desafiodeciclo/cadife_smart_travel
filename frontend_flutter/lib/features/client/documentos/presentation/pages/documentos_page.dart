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
class DocumentosPage extends ConsumerStatefulWidget {
  const DocumentosPage({super.key});

  @override
  ConsumerState<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends ConsumerState<DocumentosPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Documento> _applyFilters(List<Documento> docs) {
    if (_searchQuery.isEmpty) return docs;
    final q = _searchQuery.toLowerCase();
    return docs.where((d) => d.name.toLowerCase().contains(q)).toList();
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
            const SizedBox(height: kToolbarHeight),
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
              ),
            ),
            // Principais Documentos Section
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
                          color: Theme.of(context).textTheme.titleLarge?.color,
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
                        return const AppEmptyState(type: EmptyType.emptySearch);
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
