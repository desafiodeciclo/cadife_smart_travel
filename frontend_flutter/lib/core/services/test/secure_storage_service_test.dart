import 'package:cadife_smart_travel/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorageService', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureStorageService service;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      service = SecureStorageService(storage: mockStorage);
    });

    group('write', () {
      test('escreve valor criptografado com sucesso', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) => Future.value());

        await service.write(key: 'test_key', value: 'test_value');

        verify(() => mockStorage.write(key: 'test_key', value: 'test_value')).called(1);
      });

      test('lança SecureStorageException em caso de erro', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenThrow(Exception('Storage error'));

        expect(
          () => service.write(key: 'test_key', value: 'test_value'),
          throwsA(isA<SecureStorageException>()),
        );
      });
    });

    group('read', () {
      test('retorna valor criptografado com sucesso', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value('test_value'));

        final result = await service.read(key: 'test_key');

        expect(result, equals('test_value'));
        verify(() => mockStorage.read(key: 'test_key')).called(1);
      });

      test('retorna null se chave não existir', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(null));

        final result = await service.read(key: 'non_existent_key');

        expect(result, isNull);
      });

      test('lança SecureStorageException em caso de erro', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenThrow(Exception('Storage error'));

        expect(
          () => service.read(key: 'test_key'),
          throwsA(isA<SecureStorageException>()),
        );
      });
    });

    group('writeJson', () {
      test('escreve objeto JSON criptografado com sucesso', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) => Future.value());

        final data = {'email': 'test@example.com', 'name': 'Test User'};
        await service.writeJson(key: 'profile', value: data);

        verify(() => mockStorage.write(
          key: 'profile',
          value: any(named: 'value'),
        )).called(1);
      });
    });

    group('readJson', () {
      test('retorna objeto JSON decodificado com sucesso', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value('{"email":"test@example.com"}'));

        final result = await service.readJson(key: 'profile');

        expect(result, isA<Map<String, dynamic>>());
        expect(result?['email'], equals('test@example.com'));
      });

      test('retorna null se chave não existir', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(null));

        final result = await service.readJson(key: 'non_existent');

        expect(result, isNull);
      });
    });

    group('delete', () {
      test('deleta chave com sucesso', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) => Future.value());

        await service.delete(key: 'test_key');

        verify(() => mockStorage.delete(key: 'test_key')).called(1);
      });
    });

    group('deleteAll', () {
      test('deleta todas as chaves com sucesso', () async {
        when(() => mockStorage.deleteAll()).thenAnswer((_) => Future.value());

        await service.deleteAll();

        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    group('containsKey', () {
      test('retorna true se chave existe', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value('some_value'));

        final exists = await service.containsKey(key: 'test_key');

        expect(exists, isTrue);
      });

      test('retorna false se chave não existe', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(null));

        final exists = await service.containsKey(key: 'non_existent');

        expect(exists, isFalse);
      });
    });
  });
}
