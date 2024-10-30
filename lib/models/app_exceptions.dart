// app_exceptions.dart

abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, {this.originalError});

  @override
  String toString() => 'AppException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class NetworkException extends AppException {
  final bool isConnectivityError;
  final bool isServerError;
  final int? statusCode;
  final String? code;

  NetworkException(
      super.message, {
        this.isConnectivityError = false,
        this.isServerError = false,
        this.statusCode,
        this.code,
        super.originalError,
      });
}

class DataParsingException extends AppException {
  DataParsingException(super.message, {super.originalError});
}

class ResourceNotFoundException extends AppException {
  final String code;

  ResourceNotFoundException(super.message, {required this.code, super.originalError});
}

class ValidationException extends AppException {
  final String code;

  ValidationException(super.message, {required this.code, super.originalError});
}

class VehicleInfoException extends AppException {
  final String? vin;

  VehicleInfoException(super.message, {this.vin, super.originalError});
}