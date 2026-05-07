import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/repositories/i_documento_repository.dart';
import 'package:fpdart/fpdart.dart';

class MockDocumentoRepository implements IDocumentoRepository {
  @override
  Future<Either<Failure, List<Documento>>> getMyDocuments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right([
      Documento(
        id: '1',
        name: 'Voucher Hotel',
        type: DocumentType.pdf,
        size: 1258291,
        url: 'https://example.com/voucher.pdf',
        category: 'Hospedagem',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Documento(
        id: '2',
        name: 'Seguro Viagem',
        type: DocumentType.pdf,
        size: 838860,
        url: 'https://example.com/seguro.pdf',
        category: 'Seguro',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Documento(
        id: '3',
        name: 'Passagens Aéreas',
        type: DocumentType.pdf,
        size: 2621440,
        url: 'https://example.com/passagens.pdf',
        category: 'Transporte',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<Documento>>> getDocumentsByTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Retorna os mesmos mocks por enquanto, ou uma lista vazia se não quiser repetir
    return getMyDocuments();
  }
}
