// vehicle_info_provider.dart

import 'package:flutter/foundation.dart';
import '../models/vehicle_info.dart';
import '../models/app_exceptions.dart';
import 'nhtsa_api_service.dart';
import 'google_image_service.dart';
import 'error_handling_service.dart';
import 'package:logging/logging.dart';

class VehicleInfoProvider with ChangeNotifier {
  final NHTSAApiService _nhtsaService = NHTSAApiService();
  final GoogleImageService _imageService = GoogleImageService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  final _log = Logger('VehicleInfoProvider');

  VehicleInfo? _vehicleInfo;
  List<Map<String, dynamic>> _vehicleVariants = [];
  bool _isLoading = false;
  AppException? _error;

  VehicleInfo? get vehicleInfo => _vehicleInfo;
  List<Map<String, dynamic>> get vehicleVariants => _vehicleVariants;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  String getUserFriendlyError() {
    if (_error == null) return '';

    if (_error is NetworkException) {
      final networkError = _error as NetworkException;

      if (networkError.statusCode == 503) {
        return 'The NHTSA vehicle information service is temporarily unavailable.\n\n'
            'This is a known issue with the government database service, not with your device '
            'or internet connection.\n\n'
            'Please try again in a few minutes.';
      }

      if (networkError.isConnectivityError) {
        return 'Please check your internet connection and try again.';
      } else if (networkError.isServerError) {
        return 'Service is temporarily unavailable. Please try again later.';
      } else {
        return 'Unable to process your request. Please try again.';
      }
    } else if (_error is ResourceNotFoundException) {
      return 'Vehicle information not found. Please verify the VIN and try again.';
    } else if (_error is ValidationException) {
      return 'Invalid vehicle data received. Please try again.';
    } else if (_error is VehicleInfoException) {
      if (_error!.originalError is NetworkException) {
        final networkError = _error!.originalError as NetworkException;
        if (networkError.statusCode == 503) {
          return 'The NHTSA vehicle information service is temporarily unavailable.\n\n'
              'This is a known issue with the government database service, not with your device '
              'or internet connection.\n\n'
              'Please try again in a few minutes.';
        }
      }
      return 'Error retrieving vehicle information. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> fetchVehicleInfo(String vin) async {
    _setLoadingState(true);
    _error = null;

    try {
      await _errorHandler.withRetry(
        operation: () async {
          // First fetch basic vehicle info
          _vehicleInfo = await _nhtsaService.getVehicleInfo(vin);

          if (_vehicleInfo != null) {
            // Fetch all additional data in parallel
            final futures = await Future.wait([
              // Image fetch with timeout
              _errorHandler.withTimeout(
                operation: () async {
                  final imageQuery = '${_vehicleInfo!.year} ${_vehicleInfo!.make} ${_vehicleInfo!.model}';
                  return await _imageService.getVehicleImage(imageQuery);
                },
                timeout: const Duration(seconds: 10),
                onTimeout: () => 'https://via.placeholder.com/300x200?text=Vehicle+Image',
              ),
              // Fetch recalls
              _nhtsaService.getRecalls(
                _vehicleInfo!.make,
                _vehicleInfo!.model,
                _vehicleInfo!.year.toString(),
              ),
              // Fetch vehicle variants
              _nhtsaService.getVehicleVariants(
                _vehicleInfo!.year.toString(),
                _vehicleInfo!.make,
                _vehicleInfo!.model,
              ),
            ]);

            // Update vehicle info with all fetched data
            final imageUrl = futures[0] as String;
            final recalls = futures[1] as List<Map<String, dynamic>>;
            _vehicleVariants = futures[2] as List<Map<String, dynamic>>;

            _vehicleInfo = _vehicleInfo!.copyWith(
              imageUrl: imageUrl,
              recalls: recalls,
              complaints: [], // Initialize with empty list since we're handling complaints separately
            );

          } else {
            throw VehicleInfoException(
              'Vehicle info is null after fetching',
              vin: vin,
            );
          }
        },
        maxAttempts: 3,
        shouldRetry: (e) {
          return e is NetworkException || e is ResourceNotFoundException;
        },
      );
    } catch (e) {
      if (e is AppException) {
        _error = e;
      } else {
        _error = VehicleInfoException(
          'An unexpected error occurred',
          vin: vin,
          originalError: e,
        );
      }
      _vehicleInfo = null;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> selectVariantAndFetchSafetyRatings(String vehicleId) async {
    _setLoadingState(true);
    _error = null;

    try {
      await _errorHandler.withRetry(
        operation: () async {
          final selectedVariant = _vehicleVariants.firstWhere(
                (variant) => variant['VehicleId'].toString() == vehicleId,
            orElse: () => throw ResourceNotFoundException(
              'Selected variant not found',
              code: 'VARIANT_NOT_FOUND',
            ),
          );

          final safetyRatings = await _nhtsaService.getSafetyRatings(vehicleId);

          _vehicleInfo = _vehicleInfo?.copyWith(
            trim: selectedVariant['Trim'] ?? _vehicleInfo?.trim ?? 'N/A',
            bodyClass: selectedVariant['BodyStyle'] ?? _vehicleInfo?.bodyClass ?? 'N/A',
            safetyRatings: safetyRatings,
          );
        },
        maxAttempts: 2,
      );
    } catch (e) {
      if (e is AppException) {
        _error = e;
      } else {
        _error = VehicleInfoException(
          'Failed to fetch variant information',
          originalError: e,
        );
      }
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearVehicleInfo() {
    _vehicleInfo = null;
    _vehicleVariants = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}