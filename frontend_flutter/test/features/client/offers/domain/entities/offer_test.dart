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
      'final_price': '15000.00',
      'base_price': '18000.00',
      'destination_image_url': 'https://example.com/paris.jpg',
      'departure_date': '2026-06-01T00:00:00.000Z',
      'return_date': '2026-06-08T00:00:00.000Z',
      'duration_days': 7,
      'discounts': {'early_bird': 10.0},
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
    };

    test('parses offer with all fields filled', () {
      final offer = Offer.fromJson(fullJson);

      expect(offer.id, 'offer-001');
      expect(offer.price, 15000.0);
      expect(offer.basePrice, 18000.0);
      expect(offer.finalPrice, 15000.0); // final_price from backend (already computed)
      expect(offer.rating, 0.0);
      expect(offer.hasDiscount, true);
      expect(offer.discountPercent, 10.0);
      expect(offer.imageUrl, 'https://example.com/paris.jpg');
      expect(offer.daysCount, 7);
      expect(offer.dates, isNotNull);
      expect(offer.departureDate, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(offer.returnDate, DateTime.parse('2026-06-08T00:00:00.000Z'));
      expect(offer.availableSpot, true);
      expect(offer.availableSpots, 10);
      expect(offer.spotsReserved, 2);
      expect(offer.highlights.length, 2);
    });

    test('parses offer when final_price is null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['final_price'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.price, 0.0);
      expect(offer.basePrice, 18000.0);
      expect(offer.finalPrice, 0.0);
    });

    test('parses offer when base_price is null and final_price is present', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['base_price'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.price, 15000.0);
      expect(offer.basePrice, 0.0);
    });

    test('parses offer when both final_price and base_price are null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['final_price'] = null;
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
        'final_price': '5000.00',
        'base_price': '5000.00',
        'departure_date': '2026-07-01T00:00:00.000Z',
        'return_date': '2026-07-05T00:00:00.000Z',
        'available_spots': 5,
        'spots_reserved': 0,
      };

      final offer = Offer.fromJson(json);

      expect(offer.id, 'offer-002');
      expect(offer.price, 5000.0);
      expect(offer.basePrice, 5000.0);
      expect(offer.category, 'Geral');
      expect(offer.hasDiscount, false);
      expect(offer.discountPercent, 0.0);
      expect(offer.availableSpot, true);
      expect(offer.currency, 'BRL');
      expect(offer.travelers, 1);
    });

    test('parses offer when dates are null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['departure_date'] = null;
      json['return_date'] = null;

      final offer = Offer.fromJson(json);

      expect(offer.dates, isNull);
      expect(offer.departureDate, isNull);
      expect(offer.returnDate, isNull);
    });

    test('parses offer when date fields are absent', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('departure_date');
      json.remove('return_date');

      final offer = Offer.fromJson(json);

      expect(offer.dates, isNull);
      expect(offer.departureDate, isNull);
      expect(offer.returnDate, isNull);
    });

    test('parses offer with multiple discounts and uses max value', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['discounts'] = {'early_bird': 10.0, 'black_friday': 15.0, 'loyalty': 5.0};

      final offer = Offer.fromJson(json);

      expect(offer.hasDiscount, true);
      expect(offer.discountPercent, 15.0);
    });

    test('parses offer when fully reserved', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['available_spots'] = 10;
      json['spots_reserved'] = 10;

      final offer = Offer.fromJson(json);

      expect(offer.availableSpot, false);
      expect(offer.availableSpots, 10);
      expect(offer.spotsReserved, 10);
    });

    test('parses offer with empty discounts as no discount', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['discounts'] = {};

      final offer = Offer.fromJson(json);

      expect(offer.hasDiscount, false);
      expect(offer.discountPercent, 0.0);
    });

    test('serializes offer with dates null', () {
      const offer = Offer(
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
      expect(json['departure_date'], isNull);
      expect(json['return_date'], isNull);
      expect(json['final_price'], '8000.00');
      expect(json['base_price'], '8000.00');
    });

    test('serializes offer with discount', () {
      const offer = Offer(
        id: 'offer-004',
        title: 'Com desconto',
        destination: 'Lisboa',
        category: 'Europeu',
        description: 'Pacote com desconto',
        price: 9000.0,
        imageUrl: '',
        rating: 0.0,
        daysCount: 5,
        basePrice: 10000.0,
        hasDiscount: true,
        discountPercent: 10.0,
      );

      final json = offer.toJson();
      expect(json['discounts'], isNotNull);
      expect((json['discounts'] as Map<String, dynamic>)['default'], 10.0);
    });
  });
}
