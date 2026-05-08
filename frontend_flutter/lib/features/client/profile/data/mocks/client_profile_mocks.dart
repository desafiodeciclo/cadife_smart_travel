import 'package:cadife_smart_travel/features/client/profile/domain/entities/diary_entry.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/suitcase_item.dart';

abstract class ClientProfileMocks {
  static const int mockTotalTrips = 12;
  static const List<String> mockCountriesIso = ['BR', 'US', 'FR', 'JP', 'IT'];

  static List<DiaryEntry> diaryEntries() => [
        DiaryEntry(
          id: 'diary-001',
          tripId: 'trip-paris',
          photoUrl:
              'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600',
          note:
              'Primeiro dia em Paris! A Torre Eiffel é ainda mais linda pessoalmente 🗼',
          date: DateTime(2024, 5, 10),
          createdAt: DateTime(2024, 5, 10),
          updatedAt: DateTime(2024, 5, 10),
        ),
        DiaryEntry(
          id: 'diary-002',
          tripId: 'trip-paris',
          photoUrl:
              'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=600',
          note: 'Museu do Louvre: arte, história e magia em cada quadro',
          date: DateTime(2024, 5, 11),
          createdAt: DateTime(2024, 5, 11),
          updatedAt: DateTime(2024, 5, 11),
        ),
        DiaryEntry(
          id: 'diary-003',
          tripId: 'trip-paris',
          photoUrl:
              'https://images.unsplash.com/photo-1431274172761-fca41d930114?w=600',
          note: 'Croissant de manhã, vinho à noite — Paris perfeita!',
          date: DateTime(2024, 5, 12),
          sharingToken: 'share-abc123',
          isShared: true,
          createdAt: DateTime(2024, 5, 12),
          updatedAt: DateTime(2024, 5, 12),
        ),
        DiaryEntry(
          id: 'diary-004',
          tripId: 'trip-tokyo',
          photoUrl:
              'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
          note: 'Cruzamento de Shibuya à noite — energia pura!',
          date: DateTime(2024, 3, 20),
          sharingToken: 'share-xyz456',
          isShared: true,
          createdAt: DateTime(2024, 3, 20),
          updatedAt: DateTime(2024, 3, 20),
        ),
        DiaryEntry(
          id: 'diary-005',
          tripId: 'trip-tokyo',
          photoUrl:
              'https://images.unsplash.com/photo-1480796927426-f609979314bd?w=600',
          note: 'Templo Senso-ji de madrugada: paz absoluta',
          date: DateTime(2024, 3, 21),
          createdAt: DateTime(2024, 3, 21),
          updatedAt: DateTime(2024, 3, 21),
        ),
      ];

  static Map<String, String> tripNames() => {
        'trip-paris': '🇫🇷 Paris, França',
        'trip-tokyo': '🇯🇵 Tóquio, Japão',
      };

  static List<SuitcaseItem> suitcaseItems(String tripId) {
    if (tripId == 'trip-paris') {
      return [
        SuitcaseItem(
          id: 'item-001',
          tripId: tripId,
          category: 'Documentos',
          name: 'Passaporte',
          packed: true,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-002',
          tripId: tripId,
          category: 'Documentos',
          name: 'Seguro viagem',
          packed: false,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-003',
          tripId: tripId,
          category: 'Roupas',
          name: 'Casaco de inverno',
          packed: true,
          isSuggestion: true,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-004',
          tripId: tripId,
          category: 'Roupas',
          name: 'Luvas e cachecol',
          packed: false,
          isSuggestion: true,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-005',
          tripId: tripId,
          category: 'Eletrônicos',
          name: 'Adaptador de tomada europeu',
          packed: false,
          isSuggestion: true,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-006',
          tripId: tripId,
          category: 'Eletrônicos',
          name: 'Carregador portátil',
          packed: true,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-007',
          tripId: tripId,
          category: 'Higiene',
          name: 'Protetor solar',
          packed: false,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
      ];
    }
    if (tripId == 'trip-tokyo') {
      return [
        SuitcaseItem(
          id: 'item-t001',
          tripId: tripId,
          category: 'Documentos',
          name: 'Passaporte',
          packed: false,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-t002',
          tripId: tripId,
          category: 'Roupas',
          name: 'Roupas confortáveis para caminhada',
          packed: false,
          isSuggestion: true,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'item-t003',
          tripId: tripId,
          category: 'Outros',
          name: 'Cartão de transporte IC',
          packed: false,
          isSuggestion: true,
          createdAt: DateTime.now(),
        ),
      ];
    }
    if (tripId == 'essentials') {
      return [
        SuitcaseItem(
          id: 'ess-001',
          tripId: tripId,
          category: 'Documentos',
          name: 'RG / CNH',
          packed: true,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'ess-002',
          tripId: tripId,
          category: 'Higiene',
          name: 'Escova de dentes',
          packed: false,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'ess-003',
          tripId: tripId,
          category: 'Eletrônicos',
          name: 'Carregador de celular',
          packed: true,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
      ];
    }
    return [];
  }
}
