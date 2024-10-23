// error_handling_service.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_exceptions.dart';  // Add this import

class ErrorHandlingService {
  final _log = Logger('ErrorHandlingService');
  final Connectivity _connectivity = Connectivity();

  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (e is Exception &&
            attempt < maxAttempts &&
            (shouldRetry?.call(e) ?? _defaultShouldRetry(e))) {

          _log.warning(
              'Operation failed (Attempt $attempt/$maxAttempts). Retrying in ${delay.inSeconds}s',
              e
          );

          await Future.delayed(delay);
          delay *= 2; // Exponential backoff

          // Check connectivity before retry if it was a network error
          if (e is NetworkException) {
            final connectivityResult = await _connectivity.checkConnectivity();
            if (connectivityResult == ConnectivityResult.none) {
              _log.severe('No network connectivity available for retry');
              rethrow;
            }
          }
        } else {
          _log.severe(
              'Operation failed permanently after $attempt attempts',
              e
          );
          rethrow;
        }
      }
    }
  }

  bool _defaultShouldRetry(Exception e) {
    if (e is NetworkException) {
      // Retry server errors and connectivity issues, but not client errors
      return e.isServerError || e.isConnectivityError;
    }
    if (e is DataParsingException) {
      // Don't retry parsing errors as they're unlikely to succeed
      return false;
    }
    return false;
  }

  Future<T> withTimeout<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    T Function()? onTimeout,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          _log.warning('Operation timed out after ${timeout.inSeconds} seconds');
          if (onTimeout != null) {
            return onTimeout();
          }
          throw NetworkException(
              'Operation timed out',
              code: 'TIMEOUT'
          );
        },
      );
    } catch (e) {
      _log.severe('Error in withTimeout', e);
      rethrow;
    }
  }
}