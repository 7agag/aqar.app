class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class UnauthorizedException implements Exception {
  @override
  String toString() => 'UnauthorizedException';
}

class NetworkException implements Exception {
  @override
  String toString() => 'NetworkException: No internet connection';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}