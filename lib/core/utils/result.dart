class Result<T> {
  const Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(Object error) => Result._(error: error);

  final T? data;
  final Object? error;

  bool get isSuccess => error == null;
}
