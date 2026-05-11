import 'dart:async';

/// Stream broadcast de eventos `travel_updated` recebidos via FCM.
/// FCMManager emite; ItineraryNotifier consome para invalidar o cache.
class TravelUpdateBus {
  TravelUpdateBus._();

  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void emit(String travelId) => _controller.add(travelId);
}
