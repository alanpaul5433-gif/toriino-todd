class AppException implements Exception {
  final String? massage;
  final String? prefix;
  AppException([this.massage, this.prefix]);

  @override
  String toString() {
    return "$prefix,$massage";
  }
}

class InternetException extends AppException {
  InternetException(String massage) : super(massage, "Internet Error");
}

class RequestTimeOut extends AppException {
  RequestTimeOut(String massage) : super(massage, "Request Time Out");
}

class ServerException extends AppException {
  ServerException(String massage) : super(massage, "Internal Server Error");
}

class InvalidUrlException extends AppException {
  InvalidUrlException(String massage) : super(massage, "Invsalid URL Error");
}

class FetchdataException extends AppException {
  FetchdataException(String massage) : super(massage,"");
}


/// HTTP 402 — the server requires payment before this action (e.g. enrolling
/// in a paid course or opening paid lesson media). [price] is the course price
/// when the server includes it.
class PaymentRequiredException extends AppException {
  final double? price;
  PaymentRequiredException(String massage, {this.price})
      : super(massage, "Payment Required");
}

/// HTTP 403 — the caller is signed in but not allowed to see this resource.
/// Carries the server's own {error} message.
class ForbiddenException extends AppException {
  ForbiddenException(String massage) : super(massage, "Forbidden");
}

/// HTTP 404 — the requested resource does not exist.
/// Carries the server's own {error} message.
class NotFoundException extends AppException {
  NotFoundException(String massage) : super(massage, "Not Found");
}

/// HTTP 409 — conflicts with the current state (e.g. the session is already
/// paid). Carries the server's own {error} message.
class ConflictException extends AppException {
  ConflictException(String massage) : super(massage, "Conflict");
}
