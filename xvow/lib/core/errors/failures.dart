

sealed class Failure {
	final String message;
	const Failure(this.message);
}

class AuthFailure extends Failure {
	const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
	const NetworkFailure(super.message);
}

class DatabaseFailure extends Failure {
	const DatabaseFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}