import 'package:cadife_smart_travel/features/client/domain/entities/travel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Travel.fromJson', () {
    test('parses travel with end_date filled', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': '550e8400-e29b-41d4-a716-446655440001',
        'destination': 'Paris',
        'start_date': '2026-06-01T00:00:00.000Z',
        'end_date': '2026-06-10T00:00:00.000Z',
        'status': 'upcoming',
        'image_url': 'https://example.com/paris.jpg',
        'description': 'Viagem de lua de mel',
      };

      final travel = Travel.fromJson(json);

      expect(travel.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(travel.destination, 'Paris');
      expect(travel.startDate, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(travel.endDate, DateTime.parse('2026-06-10T00:00:00.000Z'));
      expect(travel.status, 'upcoming');
      expect(travel.imageUrl, 'https://example.com/paris.jpg');
      expect(travel.description, 'Viagem de lua de mel');
    });

    test('parses travel with end_date null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': '550e8400-e29b-41d4-a716-446655440001',
        'destination': 'Paris',
        'start_date': '2026-06-01T00:00:00.000Z',
        'end_date': null,
        'status': 'upcoming',
        'image_url': null,
        'description': null,
      };

      final travel = Travel.fromJson(json);

      expect(travel.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(travel.destination, 'Paris');
      expect(travel.startDate, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(travel.endDate, isNull);
      expect(travel.status, 'upcoming');
      expect(travel.imageUrl, isNull);
      expect(travel.description, isNull);
    });

    test('parses travel with end_date absent', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': '550e8400-e29b-41d4-a716-446655440001',
        'destination': 'Paris',
        'start_date': '2026-06-01T00:00:00.000Z',
        'status': 'upcoming',
      };

      final travel = Travel.fromJson(json);

      expect(travel.endDate, isNull);
    });
  });

  group('Travel.toJson', () {
    test('serializes travel with endDate null', () {
      final travel = Travel(
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: '550e8400-e29b-41d4-a716-446655440001',
        destination: 'Paris',
        startDate: DateTime(2026, 6, 1),
        endDate: null,
        status: 'upcoming',
      );

      final json = travel.toJson();

      expect(json['end_date'], isNull);
    });
  });
}
