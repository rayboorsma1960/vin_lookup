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
      String message, {
        this.isConnectivityError = false,
        this.isServerError = false,
        this.statusCode,
        this.code,
        dynamic originalError,
      }) : super(message, originalError: originalError);
}

class DataParsingException extends AppException {
  DataParsingException(String message, {dynamic originalError})
      : super(message, originalError: originalError);
}

class ResourceNotFoundException extends AppException {
  final String code;

  ResourceNotFoundException(String message, {required this.code, dynamic originalError})
      : super(message, originalError: originalError);
}

class ValidationException extends AppException {
  final String code;

  ValidationException(String message, {required this.code, dynamic originalError})
      : super(message, originalError: originalError);
}

class VehicleInfoException extends AppException {
  final String? vin;

  VehicleInfoException(String message, {this.vin, dynamic originalError})
      : super(message, originalError: originalError);
}