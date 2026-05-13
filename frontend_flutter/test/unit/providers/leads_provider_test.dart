import 'package:cadife_smart_travel/models/lead.dart';
import 'package:cadife_smart_travel/providers/api_provider.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockDio),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LeadsProvider Tests', () {
    test('Estado Inicial: Busca página 1 sem filtros', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: {
          'items': [],
          'total': 0,
          'page': 1,
          'pages': 1,
        },
        requestOptions: RequestOptions(path: '/leads/'),
      ));

      // O primeiro estado lido deve ser loading
      expect(container.read(leadsProvider), const AsyncLoading<LeadsListResponse>());

      // Aguarda o resultado assíncrono
      final data = await container.read(leadsProvider.future);
      
      expect(data.page, 1);
      expect(data.items, isEmpty);
      
      verify(() => mockDio.get(
        '/leads/',
        queryParameters: {'page': 1, 'size': 10},
      )).called(1);
    });

    test('Mudança de Página: changePage(2) altera estado e busca novos dados', () async {
      // Mock para o build inicial
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: {
          'items': [],
          'total': 20,
          'page': 1,
          'pages': 2,
        },
        requestOptions: RequestOptions(path: '/leads/'),
      ));

      await container.read(leadsProvider.future);

      // Mock para a página 2
      when(() => mockDio.get(
        any(),
        queryParameters: {
          'page': 2,
          'size': 10,
        },
      )).thenAnswer((_) async => Response(
        data: {
          'items': [],
          'total': 20,
          'page': 2,
          'pages': 2,
        },
        requestOptions: RequestOptions(path: '/leads/'),
      ));

      await container.read(leadsProvider.notifier).changePage(2);
      
      final data = container.read(leadsProvider).value;
      expect(data?.page, 2);
      
      verify(() => mockDio.get(
        '/leads/',
        queryParameters: {'page': 2, 'size': 10},
      )).called(1);
    });

    test('Filtro Reativo: filterByStatus("qualificado") reseta página', () async {
      // Build inicial
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: {
          'items': [],
          'total': 5,
          'page': 1,
          'pages': 1,
        },
        requestOptions: RequestOptions(path: '/leads/'),
      ));

      await container.read(leadsProvider.future);

      await container.read(leadsProvider.notifier).filterByStatus('qualificado');
      
      final data = container.read(leadsProvider).value;
      expect(data?.page, 1);
      
      verify(() => mockDio.get(
        '/leads/',
        queryParameters: {'page': 1, 'size': 10, 'status': 'qualificado'},
      )).called(1);
    });

    test('Tratamento de Erros: Captura erro da API corretamente', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/leads/'),
        error: 'Erro de Servidor',
        type: DioExceptionType.badResponse,
      ));

      // Tenta ler o provider que vai falhar
      try {
        await container.read(leadsProvider.future);
      } catch (_) {}
      
      expect(container.read(leadsProvider).hasError, true);
      expect(container.read(leadsProvider).error, isA<DioException>());
    });
  });
}
