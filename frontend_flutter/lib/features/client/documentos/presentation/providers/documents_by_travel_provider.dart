import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// AsyncNotifier que busca documentos de uma viagem específica
/// via endpoint GET /travels/{travelId}/documents.
class DocumentsByTravelNotifier
    extends FamilyAsyncNotifier<List<Documento>, String> {
  @override
  Future<List<Documento>> build(String travelId) async {
    return _fetchDocuments(travelId);
  }

  Future<List<Documento>> _fetchDocuments(String travelId) async {
    final dio = GetIt.I<Dio>();
    try {
      final endpoint =
          '${ApiConstants.baseUrl}${ApiConstants.travelDocuments(travelId)}';
      final response = await dio.get(endpoint);
      final documents = (response.data['documents'] as List)
          .map((e) => Documento.fromJson(e as Map<String, dynamic>))
          .toList();
      return documents;
    } catch (e, st) {
      throw AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDocuments(arg));
  }
}

/// Provider family para documentos de uma viagem.
/// Uso: ref.watch(documentsByTravelProvider('trip-uuid'))
final documentsByTravelProvider = AsyncNotifierProviderFamily<
    DocumentsByTravelNotifier, List<Documento>, String>(
  DocumentsByTravelNotifier.new,
);
