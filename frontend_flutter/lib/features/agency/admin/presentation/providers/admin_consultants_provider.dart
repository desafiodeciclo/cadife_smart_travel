import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// Entidade representando um consultor na gestão de admin.
class AdminConsultant {
  const AdminConsultant({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.metrics,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final ConsultantMetrics metrics;
  final String? phone;

  factory AdminConsultant.fromJson(Map<String, dynamic> json) {
    return AdminConsultant(
      id: json['id'] as String,
      name: json['nome'] as String,
      email: json['email'] as String,
      phone: json['telefone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['perfil'],
        orElse: () => UserRole.consultor,
      ),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['criado_em'] as String),
      metrics: ConsultantMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }
}

class ConsultantMetrics {
  const ConsultantMetrics({
    required this.totalLeads,
    required this.activeLeads,
    required this.closedLeads,
  });

  final int totalLeads;
  final int activeLeads;
  final int closedLeads;

  factory ConsultantMetrics.fromJson(Map<String, dynamic> json) {
    return ConsultantMetrics(
      totalLeads: json['total_leads'] as int? ?? 0,
      activeLeads: json['active_leads'] as int? ?? 0,
      closedLeads: json['closed_leads'] as int? ?? 0,
    );
  }
}

/// Provider que busca a lista de consultores do endpoint admin.
final adminConsultantsProvider = FutureProvider<List<AdminConsultant>>((ref) async {
  final dio = GetIt.I<Dio>();
  final response = await dio.get('${ApiConstants.baseUrl}/admin/users');
  final List<dynamic> items = response.data['items'] as List<dynamic>;
  return items.map((e) => AdminConsultant.fromJson(e as Map<String, dynamic>)).toList();
});

/// Notifier para operações de admin (criar, atualizar, deletar).
class AdminConsultantsNotifier extends StateNotifier<AsyncValue<List<AdminConsultant>>> {
  AdminConsultantsNotifier() : super(const AsyncValue.loading());

  final Dio _dio = GetIt.I<Dio>();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/admin/users');
      final List<dynamic> items = response.data['items'] as List<dynamic>;
      final consultants = items
          .map((e) => AdminConsultant.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(consultants);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createConsultant({
    required String name,
    required String email,
    String? phone,
    UserRole role = UserRole.consultor,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/admin/users',
        data: {
          'nome': name,
          'email': email,
          'telefone': phone,
          'role': role.name,
        },
      );
      await refresh();
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConsultant(
    String id, {
    String? name,
    String? email,
    String? phone,
    bool? isActive,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.baseUrl}/admin/users/$id',
        data: {
          'nome': name,
          'email': email,
          'telefone': phone,
          'is_active': isActive,
        },
      );
      await refresh();
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteConsultant(String id, {String? reassignToId}) async {
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/admin/users/$id',
        queryParameters: reassignToId != null ? {'reassign_to': reassignToId} : null,
      );
      await refresh();
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminConsultantsNotifierProvider =
    StateNotifierProvider<AdminConsultantsNotifier, AsyncValue<List<AdminConsultant>>>(
  (ref) => AdminConsultantsNotifier(),
);
