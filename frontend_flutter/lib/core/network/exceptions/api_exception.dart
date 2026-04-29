sealed class ApiException implements Exception {
  const ApiException();
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([this.message]);
  final String? message;
}

class ForbiddenException extends ApiException {
  const ForbiddenException();
}

class ConflictException extends ApiException {
  const ConflictException([this.message]);
  final String? message;
}

class ServerException extends ApiException {
  const ServerException(this.statusCode, [this.message]);
  final int statusCode;
  final String? message;
}

class NetworkException extends ApiException {
  const NetworkException([this.message]);
  final String? message;
}

class UnknownApiException extends ApiException {
  const UnknownApiException(this.originalError);
  final Object originalError;
}
