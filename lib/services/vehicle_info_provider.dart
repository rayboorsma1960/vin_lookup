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

  // Updating error type to be more specific
  VehicleInfo? get vehicleInfo => _vehicleInfo;
  List<Map<String, dynamic>> get vehicleVariants => _vehicleVariants;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  // Helper method to get user-friendly error message
  // In VehicleInfoProvider class

  String getUserFriendlyError() {
    if (_error == null) return '';

    if (_error is NetworkException) {
      final networkError = _error as NetworkException;

      // Specifically check for 503 status code
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
      // Also check VehicleInfoException's originalError for NetworkException with 503
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
    //_Log.info('Starting fetchVehicleInfo for VIN: $vin');
    _setLoadingState(true);
    _error = null;

    try {
      // Use error handler for the entire operation
      await _errorHandler.withRetry(
        operation: () async {
          // Fetch basic vehicle info
          _vehicleInfo = await _nhtsaService.getVehicleInfo(vin);

          if (_vehicleInfo != null) {
            //_Log.info('Vehicle info fetched successfully');

            // Fetch image with timeout
            await _errorHandler.withTimeout(
              operation: () async {
                final imageQuery = '${_vehicleInfo!.year} ${_vehicleInfo!.make} ${_vehicleInfo!.model}';
                //_Log.info('Fetching image for query: $imageQuery');
                final imageUrl = await _imageService.getVehicleImage(imageQuery);
                _vehicleInfo = _vehicleInfo!.copyWith(imageUrl: imageUrl);
              },
              timeout: const Duration(seconds: 10),
              onTimeout: () {
                // On timeout, just use a placeholder image
                //_Log.warning('Image fetch timed out, using placeholder');
                _vehicleInfo = _vehicleInfo!.copyWith(
                    imageUrl: 'https://via.placeholder.com/300x200?text=Vehicle+Image'
                );
              },
            );

            // Fetch vehicle variants
            _vehicleVariants = await _nhtsaService.getVehicleVariants(
                _vehicleInfo!.year.toString(),
                _vehicleInfo!.make,
                _vehicleInfo!.model
            );

            //_Log.info('Found ${_vehicleVariants.length} variants');
          } else {
            throw VehicleInfoException(
                'Vehicle info is null after fetching',
                vin: vin
            );
          }
        },
        maxAttempts: 3,
        shouldRetry: (e) {
          // Only retry network errors and not found errors
          return e is NetworkException || e is ResourceNotFoundException;
        },
      );
    } catch (e) {
      //_Log.severe('Error in fetchVehicleInfo: $e');
      if (e is AppException) {
        _error = e;
      } else {
        _error = VehicleInfoException(
            'An unexpected error occurred',
            vin: vin,
            originalError: e
        );
      }
      _vehicleInfo = null;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> selectVariantAndFetchSafetyRatings(String vehicleId) async {
    //_Log.info('Selecting variant and fetching safety ratings for vehicle ID: $vehicleId');
    _setLoadingState(true);
    _error = null;

    try {
      await _errorHandler.withRetry(
        operation: () async {
          // Find the selected variant
          final selectedVariant = _vehicleVariants.firstWhere(
                (variant) => variant['VehicleId'].toString() == vehicleId,
            orElse: () => throw ResourceNotFoundException(
                'Selected variant not found',
                code: 'VARIANT_NOT_FOUND'
            ),
          );

          // Fetch safety ratings
          final safetyRatings = await _nhtsaService.getSafetyRatings(vehicleId);

          // Update vehicle info with variant-specific details and safety ratings
          _vehicleInfo = _vehicleInfo?.copyWith(
            trim: selectedVariant['Trim'] ?? _vehicleInfo?.trim ?? 'N/A',
            bodyClass: selectedVariant['BodyStyle'] ?? _vehicleInfo?.bodyClass ?? 'N/A',
            safetyRatings: safetyRatings,
          );

          //_Log.info('Vehicle variant details updated successfully');
        },
        maxAttempts: 2,
      );
    } catch (e) {
      //_Log.severe('Error selecting variant: $e');
      if (e is AppException) {
        _error = e;
      } else {
        _error = VehicleInfoException(
            'Failed to fetch variant information',
            originalError: e
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