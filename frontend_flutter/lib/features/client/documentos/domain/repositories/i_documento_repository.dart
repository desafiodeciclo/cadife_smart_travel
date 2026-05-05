import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDocumentoRepository {
  Future<Either<Failure, List<Documento>>> getMyDocuments();
  Future<Either<Failure, List<Documento>>> getDocumentsByTrip(String tripId);
}
