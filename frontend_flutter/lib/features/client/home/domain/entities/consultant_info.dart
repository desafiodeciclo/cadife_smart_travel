import 'package:flutter/foundation.dart';

@immutable
class ConsultantInfo {
  final String id;
  final String name;
  final String phone;
  final String photoUrl;
  final String email;

  const ConsultantInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.email,
  });
}
