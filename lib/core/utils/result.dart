/// Result type for error handling
/// Uses sealed classes for exhaustive pattern matching
sealed class Result<T> {
  const Result();
}

/// Success result with data
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure result with error
final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

/// Application error types
enum ErrorType {
  storage,
  network,
  validation,
  notFound,
  permission,
  unknown,
}

/// Application error with type and message
class AppError {
  final ErrorType type;
  final String message;
  final dynamic originalError;

  const AppError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AppError($type): $message';
}

/// Extension methods for Result
extension ResultExtension<T> on Result<T> {
  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data or null
  T? get dataOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// Get error or null
  AppError? get errorOrNull {
    if (this is Failure<T>) {
      return (this as Failure<T>).error;
    }
    return null;
  }

  /// Fold result into single value
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Failure(error: final error) => onFailure(error),
    };
  }

  /// Map success value
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Failure(error: final error) => Failure(error),
    };
  }

  /// FlatMap for chaining operations
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => transform(data),
      Failure(error: final error) => Failure(error),
    };
  }

  /// Execute side effect if success
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// Execute side effect if failure
  Result<T> onFailure(void Function(AppError error) action) {
    if (this is Failure<T>) {
      action((this as Failure<T>).error);
    }
    return this;
  }

  /// Get data or throw error
  T getOrThrow() {
    return switch (this) {
      Success(data: final data) => data,
      Failure(error: final error) => throw error,
    };
  }

  /// Get data or default value
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Failure() => defaultValue,
    };
  }
}
