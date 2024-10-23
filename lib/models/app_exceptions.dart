// app_exceptions.dart

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  final int? statusCode;

  NetworkException(super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isConnectivityError => statusCode == null;
}

class DataParsingException extends AppException {
  final String? expectedType;
  final String? receivedData;

  DataParsingException(super.message, {
    this.expectedType,
    this.receivedData,
    super.code,
    super.originalError,
  });
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });
}

class ResourceNotFoundException extends AppException {
  ResourceNotFoundException(super.message, {
    super.code,
    super.originalError,
  });
}

class VehicleInfoException extends AppException {
  final String? vin;

  VehicleInfoException(super.message, {
    this.vin,
    super.code,
    super.originalError,
  });
}