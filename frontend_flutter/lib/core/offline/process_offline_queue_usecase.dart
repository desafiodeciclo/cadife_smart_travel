import 'dart:developer' as developer;
import 'package:cadife_smart_travel/core/offline/i_offline_event_repository.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProcessOfflineQueueUseCase {
  final IOfflineEventRepository _repository;

  ProcessOfflineQueueUseCase(this._repository);

  Future<void> execute() async {
    final result = await _repository.getUnsyncedEvents();
    final pendingEvents = result.getOrElse((_) => []);
    if (pendingEvents.isEmpty) return;

    for (final event in pendingEvents) {
      if (event.id == null) continue;

      final syncResult = await _repository.markAsSynced(event.id!);
      syncResult.fold(
        (failure) => developer.log(
          'Falha ao sincronizar evento "${event.title}": ${failure.message}',
          name: 'OfflineQueue',
        ),
        (_) {
          developer.log('Evento sincronizado: ${event.title}', name: 'OfflineQueue');
          Fluttertoast.showToast(
            msg: 'Sincronizado: ${event.title}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        },
      );
    }
  }
}
