import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripDocumentsPage extends ConsumerWidget {
  const TripDocumentsPage({
    required this.tripId,
    super.key,
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
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    trip.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                    ),
                  ),
                  background: trip.imageUrl != null
                      ? Hero(
                          tag: 'trip_image_${trip.id}',
                          child: Image.network(
                            trip.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(color: context.cadife.primary),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
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
      orElse: () => const PageScaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
