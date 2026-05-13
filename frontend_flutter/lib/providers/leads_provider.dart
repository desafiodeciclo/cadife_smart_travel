import 'package:cadife_smart_travel/models/lead.dart';
import 'package:cadife_smart_travel/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadsNotifier extends AsyncNotifier<LeadsListResponse> {
  int _currentPage = 1;
  String? _currentStatus;
  final int _limit = 10;

  @override
  Future<LeadsListResponse> build() async {
    return _fetchLeads();
  }

  /// Método privado para buscar leads com parâmetros de consulta.
  Future<LeadsListResponse> _fetchLeads() async {
    final dio = ref.read(apiServiceProvider);
    
    final queryParams = {
      'page': _currentPage,
      'size': _limit,
      if (_currentStatus != null && _currentStatus!.isNotEmpty) 'status': _currentStatus,
    };

    try {
      final response = await dio.get(
        '/leads/',
        queryParameters: queryParams,
      );
      
      return LeadsListResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stack) {
      // O AsyncValue.guard cuidará de capturar isso se chamado de fora,
      // mas como build() retorna o Future, o Riverpod trata o erro.
      rethrow;
    }
  }

  /// Muda a página atual e dispara uma nova busca.
  Future<void> changePage(int page) async {
    if (page == _currentPage) return;
    
    _currentPage = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeads());
  }

  /// Filtra os leads por status e reseta para a primeira página.
  Future<void> filterByStatus(String? status) async {
    if (status == _currentStatus) return;
    
    _currentStatus = status;
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeads());
  }

  // Getters para UI consultar o estado atual dos filtros
  int get currentPage => _currentPage;
  String? get currentStatus => _currentStatus;
}

final leadsProvider = AsyncNotifierProvider<LeadsNotifier, LeadsListResponse>(
  LeadsNotifier.new,
);
