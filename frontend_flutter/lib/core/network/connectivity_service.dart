import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/domain/usecases/process_offline_queue_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static void init() {
    Connectivity().onConnectivityChanged.listen((results) async {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        // Internet voltou, processa a fila
        try {
          final processQueueUseCase = sl<ProcessOfflineQueueUseCase>();
          await processQueueUseCase.execute();
        } catch (e) {
          // Em caso de inicialização precoce
        }
      }
    });
  }
}
