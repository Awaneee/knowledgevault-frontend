sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Access forbidden']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found']);
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {this.errors = const []});
  final List<FieldError> errors;
}

class FieldError {
  const FieldError({required this.field, required this.message});
  final String field;
  final String message;
}

class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict']);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Something went wrong. Please try again.']);
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection']);
}

class RateLimitException extends ApiException {
  const RateLimitException([super.message = 'Too many requests. Try again in a moment.']);
}
