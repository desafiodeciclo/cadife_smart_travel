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
        final detail = e.response?.data?['detail'] as String?;
        return ValidationFailure(detail ?? 'Dados inválidos.');
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        default:
          final detail = e.response?.data?['detail'] as String?;
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
