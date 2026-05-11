import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';

class TravelDiaryMock {
  static List<TravelDiary> getMockDiaries() {
    return [
      TravelDiary(
        id: '1',
        travelId: 'trip_123',
        travelTitle: 'Paris & London 2024',
        entries: [
          DiaryEntry(
            date: DateTime(2024, 5, 10),
            mood: DiaryMood.happy,
            title: 'Chegada em Paris',
            content:
                'Finalmente chegamos em Paris! A Torre Eiffel é ainda mais impressionante de perto. O voo foi longo mas valeu cada minuto.',
            photos: [
              'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?auto=format&fit=crop&q=80&w=400',
              'https://images.unsplash.com/photo-1520939817895-060bdaf4fe1b?auto=format&fit=crop&q=80&w=400',
              'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=400',
            ],
          ),
          DiaryEntry(
            date: DateTime(2024, 5, 11),
            mood: DiaryMood.excited,
            title: 'Museu do Louvre',
            content:
                'Vimos a Monalisa hoje. O museu é gigante, impossível ver tudo em um dia. Ficamos 5 horas e ainda assim não vimos metade.',
            photos: [
              'https://images.unsplash.com/photo-1555863792-e4f8e1b1e8d2?auto=format&fit=crop&q=80&w=400',
              'https://images.unsplash.com/photo-1549877452-9c387954fbc2?auto=format&fit=crop&q=80&w=400',
            ],
          ),
        ],
      ),
      TravelDiary(
        id: '2',
        travelId: 'trip_456',
        travelTitle: 'Férias em Natal 2023',
        entries: [
          DiaryEntry(
            date: DateTime(2023, 12, 15),
            mood: DiaryMood.relaxed,
            title: 'Praia de Ponta Negra',
            content: 'Sol, mar e descanso. O Morro do Careca é lindo ao entardecer.',
            photos: [
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=400',
            ],
          ),
          DiaryEntry(
            date: DateTime(2023, 12, 16),
            mood: DiaryMood.tired,
            title: 'Passeio de Buggy',
            content: 'Com muita emoção! Muita areia e vento, mas valeu cada segundo.',
            photos: [],
          ),
        ],
      ),
    ];
  }
}

final mockDiaries = TravelDiaryMock.getMockDiaries();
