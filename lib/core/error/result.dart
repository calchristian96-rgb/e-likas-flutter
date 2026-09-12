import 'failure.dart';

/// A Dart-3-native alternative to `Either<Failure, T>`. Every repository
/// and use case in every feature returns this instead of throwing, so
/// the presentation layer can pattern-match:
///
///   final result = await useCase();
///   switch (result) {
///     case Success(:final value) => ...
///     case Failed(:final failure) => ...
///   }
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}
