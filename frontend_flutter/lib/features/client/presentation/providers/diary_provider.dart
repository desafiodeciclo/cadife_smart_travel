import 'package:cadife_smart_travel/data/mock/travel_diary_mock.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que busca o diário de viagem pelo travelId.
final diaryProvider = FutureProvider.family<TravelDiary, String>(
  (ref, travelId) async {
    // Simula um delay de rede
    await Future.delayed(const Duration(milliseconds: 500));
    return mockDiaries.firstWhere((d) => d.travelId == travelId);
    // Preparado para: return await apiService.get('/travels/$travelId/diary');
  },
);

/// Provider para criação de um novo diário de viagem.
/// Atualmente um placeholder para a integração com a API.
final createDiaryProvider = FutureProvider((ref) async {
  // POST /travels/{travelId}/diary
  // Implementação futura
  return;
});
