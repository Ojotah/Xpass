abstract class Failure {
  const Failure(this.message);

  final String message;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
