import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offer.fromJson', () {
    final fullJson = {
      'id': 'offer-001',
      'title': 'Pacote Paris',
      'destination': 'Paris',
      'category': 'Romântico',
      'description': 'Lua de mel em Paris',
      'price': 15000.0,
      'image_url': 'https://example.com/paris.jpg',
      'rating': 4.8,
      'days_count': 7,
      'dates': {'start': '2026-06-01T00:00:00.000Z', 'end': '2026-06-08T00:00:00.000Z'},
      'has_discount': true,
      'discount_percent': 10.0,
      'available_spot': true,
      'status': 'published',
      'views': 120,
      'interests': 15,
      'conversions': 3,
      'available_spots': 10,
      'spots_reserved': 2,
      'highlights': ['Torre Eiffel', 'Museu do Louvre'],
      'amenities': ['Café da manhã', 'Wi-Fi'],
      'currency': 'BRL',
      'travelers': 2,
      'base_price': 18000.0,
    };

    test('parses offer with all fields filled', () {
      final offer = Offer.fromJson(fullJson);

      expect(offer.id, 'offer-001');
      expect(offer.price, 15000.0);
      expect(offer.basePrice, 18000.0);
      expect(offer.finalPrice, 13500.0); // 15000 * 0.9
      expect(offer.rating, 4.8);
      expect(offer.hasDiscount, true);
      expect(offer.discountPercent, 10.0);
      expect(offer.highlights.length, 2);
    });

    test('parses offer when price is null (bug regression)', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['price'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.price, 0.0);
      expect(offer.basePrice, 18000.0);
      expect(offer.finalPrice, 0.0);
    });

    test('parses offer when base_price is null and price is present', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['base_price'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.price, 15000.0);
      expect(offer.basePrice, 15000.0);
    });

    test('parses offer when both price and base_price are null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['price'] = null;
      json['base_price'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.price, 0.0);
      expect(offer.basePrice, 0.0);
      expect(offer.finalPrice, 0.0);
    });

    test('parses offer with minimal fields', () {
      final json = {
        'id': 'offer-002',
        'title': 'Miami Básico',
        'destination': 'Miami',
        'price': 5000.0,
        'dates': {'start': '2026-07-01T00:00:00.000Z', 'end': '2026-07-05T00:00:00.000Z'},
      };

      final offer = Offer.fromJson(json);

      expect(offer.id, 'offer-002');
      expect(offer.price, 5000.0);
      expect(offer.basePrice, 5000.0);
      expect(offer.category, 'Geral');
      expect(offer.hasDiscount, false);
      expect(offer.availableSpot, true);
      expect(offer.currency, 'BRL');
      expect(offer.travelers, 1);
    });

    test('parses offer when dates is null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['dates'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.dates, isNull);
      expect(offer.departureDate, isNull);
      expect(offer.returnDate, isNull);
      expect(offer.durationDays, isNull);
    });

    test('parses offer when dates field is absent', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('dates');

      final offer = Offer.fromJson(json);

      expect(offer.dates, isNull);
      expect(offer.departureDate, isNull);
      expect(offer.returnDate, isNull);
    });

    test('serializes offer with dates null', () {
      final offer = Offer(
        id: 'offer-003',
        title: 'Sem datas',
        destination: 'Bahamas',
        category: 'Praia',
        description: 'Pacote sem datas definidas',
        price: 8000.0,
        imageUrl: '',
        rating: 0.0,
        daysCount: 0,
        basePrice: 8000.0,
      );

      final json = offer.toJson();
      expect(json['dates'], isNull);
    });
  });
}
