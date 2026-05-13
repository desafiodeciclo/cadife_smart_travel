import 'package:equatable/equatable.dart';
import 'lead.dart';

class LeadsListResponse extends Equatable {
  final List<Lead> items;
  final int total;
  final int page;
  final int pages;

  const LeadsListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory LeadsListResponse.fromJson(Map<String, dynamic> json) {
    return LeadsListResponse(
      items: (json['items'] as List)
          .map((item) => Lead.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pages];
}
