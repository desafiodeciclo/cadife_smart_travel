import 'package:cadife_smart_travel/features/agency/leads/domain/entities/leads_list_response.dart';
import 'lead_api_model.dart';

class LeadsListResponseApiModel extends LeadsListResponse {
  const LeadsListResponseApiModel({
    required List<LeadApiModel> super.items,
    required super.total,
    required super.page,
    required super.pages,
  });

  factory LeadsListResponseApiModel.fromJson(Map<String, dynamic> json) {
    return LeadsListResponseApiModel(
      items: (json['items'] as List)
          .map((item) => LeadApiModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
    );
  }
}
