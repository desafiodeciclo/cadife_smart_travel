import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';

class ItineraryDay {
  const ItineraryDay({
    required this.data,
    required this.itens,
    this.notasUsuario,
  });

  final DateTime data;
  final List<ItineraryItem> itens;
  final String? notasUsuario;

  ItineraryDay copyWith({
    String? notasUsuario,
    List<ItineraryItem>? itens,
    bool clearNota = false,
  }) {
    return ItineraryDay(
      data: data,
      itens: itens ?? this.itens,
      notasUsuario: clearNota ? null : (notasUsuario ?? this.notasUsuario),
    );
  }
}
