import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  static Failure fromException(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const UnauthorizedFailure();
      }
      if (statusCode == 422) {
        final rawDetail = e.response?.data?['detail'];
        String? message;
        if (rawDetail is List) {
          final errors = <String>[];
          for (final err in rawDetail) {
            if (err is Map) {
              final msg = err['msg']?.toString();
              final loc = err['loc'] is List ? (err['loc'] as List).last?.toString() : null;
              if (msg != null && loc != null) {
                String field = loc;
                if (loc == 'nome') field = 'Nome';
                if (loc == 'email') field = 'E-mail';
                if (loc == 'password') field = 'Senha';

                String cleanMsg = msg;
                if (msg.contains('Field required')) {
                  cleanMsg = 'é obrigatório';
                } else if (msg.contains('should have at least')) {
                  final ctx = err['ctx'] as Map?;
                  final minLength = ctx?['min_length']?.toString() ?? '8';
                  cleanMsg = 'deve ter pelo menos $minLength caracteres';
                }

                errors.add('$field $cleanMsg');
              } else if (msg != null) {
                errors.add(msg);
              }
            }
          }
          if (errors.isNotEmpty) {
            message = errors.join('. ') + '.';
          }
        } else if (rawDetail is String) {
          message = rawDetail;
        }
        return ValidationFailure(message ?? 'Dados inválidos.');
      }
      if (statusCode == 409) {
        final rawDetail = e.response?.data?['detail'];
        final detail = rawDetail is String ? rawDetail : rawDetail?.toString();
        return ConflictFailure(detail ?? 'E-mail ou recurso já cadastrado.');
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        default:
          final rawDetail = e.response?.data?['detail'];
          final detail = rawDetail is String ? rawDetail : rawDetail?.toString();
          return ServerFailure(detail ?? e.message ?? 'Erro no servidor.');
      }
    }
    return GenericFailure(e.toString());
  }
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor. Tente novamente mais tarde.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessão expirada ou acesso negado.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar dados locais.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class GenericFailure extends Failure {
  const GenericFailure([super.message = 'Ocorreu um erro inesperado.']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflito: recurso já existe ou está em uso.']);
}
