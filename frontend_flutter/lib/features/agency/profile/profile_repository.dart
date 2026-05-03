import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaleGoal {
  final String month;
  final int meta;
  final int realizado;

  const SaleGoal({
    required this.month,
    required this.meta,
    required this.realizado,
  });

  factory SaleGoal.fromJson(Map<String, dynamic> json) => SaleGoal(
    month: json['mes'] as String,
    meta: json['meta'] as int,
    realizado: json['realizado'] as int,
  );
}

class ConsultorProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final List<SaleGoal> salesHistory;
  final int totalFechados;
  final double taxaConversao;

  const ConsultorProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    required this.salesHistory,
    required this.totalFechados,
    required this.taxaConversao,
  });

  factory ConsultorProfile.fromJson(Map<String, dynamic> json) =>
      ConsultorProfile(
        id: json['id'] as String,
        name: json['nome'] as String? ?? json['name'] as String,
        email: json['email'] as String,
        phone: json['telefone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        salesHistory: (json['historico_metas'] as List<dynamic>? ?? [])
            .map((e) => SaleGoal.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalFechados: json['total_fechados'] as int? ?? 0,
        taxaConversao: (json['taxa_conversao'] as num?)?.toDouble() ?? 0.0,
      );

  ConsultorProfile copyWith({String? bio, String? avatarUrl}) => ConsultorProfile(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    bio: bio ?? this.bio,
    salesHistory: salesHistory,
    totalFechados: totalFechados,
    taxaConversao: taxaConversao,
  );
}

class ProfileRepository {
  final ApiService _api;
  ProfileRepository(this._api);

  Future<ConsultorProfile> getProfile() async {
    final response = await _api.get('/consultor/profile');
    return ConsultorProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConsultorProfile> updateBio(String bio) async {
    final response = await _api.put('/consultor/profile', data: {'bio': bio});
    return ConsultorProfile.fromJson(response.data as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiServiceProvider));
});
