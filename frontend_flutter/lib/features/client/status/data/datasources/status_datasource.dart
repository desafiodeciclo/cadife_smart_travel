import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';

abstract class IStatusDatasource {
  Future<ClientTravelStatus?> getMyStatus();
  Future<ClientTravelStatus?> getStatusById(String id);
}

class StatusMockDatasource implements IStatusDatasource {
  @override
  Future<ClientTravelStatus?> getMyStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockStatus('mock-lead-123');
  }

  @override
  Future<ClientTravelStatus?> getStatusById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockStatus(id);
  }

  ClientTravelStatus _mockStatus(String id) {
    return ClientTravelStatus(
      id: id,
      status: TravelStatus.confirmado,
      destino: 'Paris, França',
      dataPartida: DateTime(2024, 10, 15),
      dataRetorno: DateTime(2024, 10, 25),
      numPessoas: 2,
      consultorNome: 'Jakeline Ferreira',
    );
  }
}
