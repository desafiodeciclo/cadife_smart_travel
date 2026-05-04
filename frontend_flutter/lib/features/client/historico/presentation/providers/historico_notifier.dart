import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que gerencia a lista de viagens do cliente para o histórico.
final historicoProvider = AsyncNotifierProvider<HistoricoNotifier, List<TripSummary>>(
  HistoricoNotifier.new,
);

class HistoricoNotifier extends AsyncNotifier<List<TripSummary>> {
  @override
  Future<List<TripSummary>> build() async {
    // Simulando busca de dados
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockHistoryTrips;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 800));
    state = AsyncData(_mockHistoryTrips);
  }

  static final _mockHistoryTrips = [
    TripSummary(
      id: 'trip-h1',
      name: 'Férias em Gramado',
      destino: 'Gramado, RS',
      dataIda: DateTime(2023, 12, 10),
      dataVolta: DateTime(2023, 12, 17),
      numPessoas: 2,
      orcamento: 4500.00,
      imageUrl: 'https://images.unsplash.com/photo-1596436805366-5d589f6075c7?auto=format&fit=crop&q=80&w=800',
    ),
    TripSummary(
      id: 'trip-h2',
      name: 'Carnaval no Rio',
      destino: 'Rio de Janeiro, RJ',
      dataIda: DateTime(2024, 2, 9),
      dataVolta: DateTime(2024, 2, 14),
      numPessoas: 4,
      orcamento: 8200.50,
      imageUrl: 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&q=80&w=800',
    ),
    TripSummary(
      id: 'trip-h3',
      name: 'Trabalho em São Paulo',
      destino: 'São Paulo, SP',
      dataIda: DateTime(2024, 3, 5),
      dataVolta: DateTime(2024, 3, 8),
      numPessoas: 1,
      orcamento: 1250.00,
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&q=80&w=800',
    ),
  ];
}
