/// Utility para tratamento de erros tipado.
///
/// Evita try/catch desenfreado — força pattern matching em sucesso/erro.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}

/// Extension para facilitar uso do Result.
extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  Object? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  T get dataOrThrow => switch (this) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };

  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(:final data) => Success(transform(data)),
      Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
    };
  }

  T getOrElse(T Function() fallback) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => fallback(),
    };
  }
}
