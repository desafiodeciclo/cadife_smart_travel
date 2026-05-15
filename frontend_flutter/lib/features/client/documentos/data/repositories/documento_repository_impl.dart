import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/repositories/i_documento_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class DocumentoRepositoryImpl implements IDocumentoRepository {
  DocumentoRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<Failure, List<Documento>>> getMyDocuments() async {
    try {
      // Tenta viagem em andamento; se não houver, pega a próxima agendada.
      final travelId = await _resolveActiveTravelId();
      if (travelId == null) return const Right([]);
      return getDocumentsByTrip(travelId);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Documento>>> getDocumentsByTrip(
    String tripId,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/travels/$tripId/documents',
      );
      final documents = (res.data!['documents'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Documento.fromJson)
          .toList();
      return Right(documents);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  Future<String?> _resolveActiveTravelId() async {
    for (final statusFilter in ['ongoing', 'upcoming']) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/travels',
        queryParameters: {'status': statusFilter},
      );
      final travels = res.data!['travels'] as List<dynamic>;
      if (travels.isNotEmpty) {
        return (travels.first as Map<String, dynamic>)['id'] as String;
      }
    }
    return null;
  }
}
