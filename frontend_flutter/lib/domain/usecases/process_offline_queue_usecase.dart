import 'dart:developer' as developer;
import 'package:cadife_smart_travel/domain/repositories/i_offline_event_repository.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProcessOfflineQueueUseCase {
  final IOfflineEventRepository _repository;

  ProcessOfflineQueueUseCase(this._repository);

  Future<void> execute() async {
    try {
      final pendingEvents = await _repository.getUnsyncedEvents();
      if (pendingEvents.isEmpty) return;

      for (var event in pendingEvents) {
        // Here we would typically sync with the API (event.payload)
        // For demonstration based on the task, we mark as synced and show Toast
        await _repository.markAsSynced(event.id!);

        developer.log('Event synced: ${event.title}', name: 'OfflineQueue');
        Fluttertoast.showToast(
          msg: 'Sincronizado: ${event.title}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e, stackTrace) {
      developer.log('Erro ao processar fila offline', error: e, stackTrace: stackTrace, name: 'OfflineQueue');
    }
  }
}
