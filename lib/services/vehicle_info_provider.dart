import 'package:flutter/foundation.dart';
import '../models/vehicle_info.dart';
import 'nhtsa_api_service.dart';
import 'google_image_service.dart';
import 'package:logging/logging.dart';

class VehicleInfoProvider with ChangeNotifier {
  final NHTSAApiService _nhtsaService = NHTSAApiService();
  final GoogleImageService _imageService = GoogleImageService();
  final _log = Logger('VehicleInfoProvider');

  VehicleInfo? _vehicleInfo;
  List<Map<String, dynamic>> _vehicleVariants = [];
  bool _isLoading = false;
  String? _error;

  VehicleInfo? get vehicleInfo => _vehicleInfo;
  List<Map<String, dynamic>> get vehicleVariants => _vehicleVariants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVehicleInfo(String vin) async {
    _log.info('Starting fetchVehicleInfo for VIN: $vin');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch basic vehicle info
      _vehicleInfo = await _nhtsaService.getVehicleInfo(vin);

      if (_vehicleInfo != null) {
        _log.info('Vehicle info fetched successfully');

        // Fetch image
        final imageQuery = '${_vehicleInfo!.year} ${_vehicleInfo!.make} ${_vehicleInfo!.model}';
        _log.info('Fetching image for query: $imageQuery');
        final imageUrl = await _imageService.getVehicleImage(imageQuery);
        _vehicleInfo = _vehicleInfo!.copyWith(imageUrl: imageUrl);

        // Fetch vehicle variants
        _vehicleVariants = await _nhtsaService.getVehicleVariants(
            _vehicleInfo!.year.toString(),
            _vehicleInfo!.make,
            _vehicleInfo!.model
        );

        _log.info('Found ${_vehicleVariants.length} variants');
      } else {
        throw Exception('Vehicle info is null after fetching');
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      _vehicleInfo = null;
      _log.severe('Error in fetchVehicleInfo: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectVariantAndFetchSafetyRatings(String vehicleId) async {
    _log.info('Selecting variant and fetching safety ratings for vehicle ID: $vehicleId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find the selected variant
      final selectedVariant = _vehicleVariants.firstWhere(
            (variant) => variant['VehicleId'].toString() == vehicleId,
        orElse: () => throw Exception('Variant not found'),
      );

      // Fetch safety ratings
      final safetyRatings = await _nhtsaService.getSafetyRatings(vehicleId);

      // Update vehicle info with variant-specific details and safety ratings
      _vehicleInfo = _vehicleInfo?.copyWith(
        trim: selectedVariant['Trim'] ?? _vehicleInfo?.trim ?? 'N/A',
        bodyClass: selectedVariant['BodyStyle'] ?? _vehicleInfo?.bodyClass ?? 'N/A',
        safetyRatings: safetyRatings,
      );

      _log.info('Vehicle variant details updated successfully');
    } catch (e) {
      _error = _getErrorMessage(e);
      _log.severe('Error selecting variant: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearVehicleInfo() {
    _vehicleInfo = null;
    _vehicleVariants = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else if (error is String) {
      return error;
    } else {
      return 'An unexpected error occurred';
    }
  }
}