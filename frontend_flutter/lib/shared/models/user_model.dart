import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.consultor,
    ),
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'phone': phone,
    'avatar_url': avatarUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    phone,
    avatarUrl,
    createdAt,
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
