
import 'package:cadife_smart_travel/core/widgets/cadife_app_bar.dart';
import 'package:cadife_smart_travel/features/client/documentos/widgets/widgets.dart';
import 'package:cadife_smart_travel/features/client/documents/documents_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripDocumentsScreen extends ConsumerWidget {
  const TripDocumentsScreen({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsWithDocumentsProvider);
    final docsAsync = ref.watch(tripDocumentsProvider(tripId));

    return tripsAsync.maybeWhen(
      data: (trips) {
        final trip = trips.firstWhere(
          (t) => t.id == tripId,
          orElse: () => throw Exception('Trip not found'),
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              CadifeAppBar(title: trip.name),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentos de ${trip.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      docsAsync.when(
                        loading: () => Column(
                          children: List.generate(4, (index) => const DocumentCardSkeleton()),
                        ),
                        error: (e, st) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erro ao carregar documentos',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (docs) {
                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 64,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhum documento disponível ainda. Seu consultor irá compartilhá-los em breve.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: docs
                                .map(
                                  (doc) => CadifeDocumentCard(
                                    document: doc,
                                    onView: () {
                                      context.push('/client/documentos/viewer', extra: doc);
                                    },
                                    onDownload: () {
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
            ],
          ),
        );
      },
      orElse: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
