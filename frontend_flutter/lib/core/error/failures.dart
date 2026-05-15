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

      // Extract message from response data
      String? detail;
      final data = e.response?.data;
      if (data is Map) {
        final rawDetail = data['detail'];
        if (rawDetail is String) {
          detail = rawDetail;
        } else if (rawDetail is List && rawDetail.isNotEmpty) {
          // FastAPI validation errors are lists
          final first = rawDetail.first;
          if (first is Map && first.containsKey('msg')) {
            detail = first['msg'].toString();
          } else {
            detail = rawDetail.toString();
          }
        } else if (rawDetail != null) {
          detail = rawDetail.toString();
        }
      }

      if (statusCode == 422) {
        return ValidationFailure(detail ?? 'Dados inválidos.');
      }
      
      if (statusCode == 409) {
        return ConflictFailure(detail ?? 'Conflito de dados.');
      }

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        default:
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
