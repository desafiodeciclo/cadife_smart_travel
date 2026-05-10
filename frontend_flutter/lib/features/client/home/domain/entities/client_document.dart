import 'package:flutter/foundation.dart';

@immutable
class ClientDocument {
  final String id;
  final String type;
  final String displayName;
  final String url;
  final DateTime uploadedAt;
  final String? expiresAt;

  const ClientDocument({
    required this.id,
    required this.type,
    required this.displayName,
    required this.url,
    required this.uploadedAt,
    this.expiresAt,
  });
}
