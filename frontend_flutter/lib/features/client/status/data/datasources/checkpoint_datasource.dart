import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/checkpoint_item.dart';
import 'package:dio/dio.dart';

abstract class ICheckpointDatasource {
  Future<List<CheckpointItem>> getCheckpoints(String leadId);
}

class CheckpointDatasource implements ICheckpointDatasource {
  const CheckpointDatasource(this._dio);

  final Dio _dio;

  @override
  Future<List<CheckpointItem>> getCheckpoints(String leadId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.leadCheckpoints(leadId),
    );
    final data = response.data!;
    final list = (data['checkpoints'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return list.map(CheckpointItem.fromJson).toList();
  }
}
