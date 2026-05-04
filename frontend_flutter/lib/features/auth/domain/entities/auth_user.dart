import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.createdAt,
    this.tipoViagem,
    this.preferencias,
    this.temPassaporte,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;
  final List<String>? tipoViagem;
  final List<String>? preferencias;
  final bool? temPassaporte;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    name: json['nome'] as String? ?? json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
      (e) => e.name == (json['perfil'] ?? json['role']),
      orElse: () => UserRole.consultor,
    ),
    phone: json['telefone'] as String? ?? json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: json['criado_em'] != null
        ? DateTime.parse(json['criado_em'] as String)
        : json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
    tipoViagem: (json['tipo_viagem'] as List<dynamic>?)?.cast<String>(),
    preferencias: (json['preferencias'] as List<dynamic>?)?.cast<String>(),
    temPassaporte: json['tem_passaporte'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': name,
    'email': email,
    'perfil': role.name,
    'telefone': phone,
    'avatar_url': avatarUrl,
    'criado_em': createdAt?.toIso8601String(),
    'tipo_viagem': tipoViagem,
    'preferencias': preferencias,
    'tem_passaporte': temPassaporte,
  };

  AuthUser copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) => AuthUser(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt,
    tipoViagem: tipoViagem ?? this.tipoViagem,
    preferencias: preferencias ?? this.preferencias,
    temPassaporte: temPassaporte ?? this.temPassaporte,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    phone,
    avatarUrl,
    createdAt,
    tipoViagem,
    preferencias,
    temPassaporte,
  ];
}

enum UserRole { admin, consultor, cliente }

class TokenModel extends Equatable {
  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: json['expires_in'] as int,
  );

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}

