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
      _vehicleInfo = await _nhtsaService.getVehicleInfo(vin);
      if (_vehicleInfo != null) {
        _log.info('Vehicle info fetched successfully');
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

        // If only one variant, fetch safety ratings directly
        if (_vehicleVariants.length == 1) {
          final safetyRatings = await _nhtsaService.getSafetyRatings(_vehicleVariants[0]['VehicleId'].toString());
          _vehicleInfo = _vehicleInfo!.copyWith(safetyRatings: safetyRatings);
        }
      } else {
        throw Exception('Vehicle info is null after fetching');
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      _vehicleInfo = null;
      _log.severe('Error in fetchVehicleInfo: $_error');
    } finally {
      _isLoading = false;
      _log.info('fetchVehicleInfo completed. Has vehicle info: ${_vehicleInfo != null}');
      notifyListeners();
    }
  }

  Future<void> selectVariantAndFetchSafetyRatings(String vehicleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final safetyRatings = await _nhtsaService.getSafetyRatings(vehicleId);
      _vehicleInfo = _vehicleInfo!.copyWith(safetyRatings: safetyRatings);
    } catch (e) {
      _error = _getErrorMessage(e);
      _log.severe('Error fetching safety ratings: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearVehicleInfo() {
    _vehicleInfo = null;
    _vehicleVariants = [];
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    } else if (error is String) {
      return error;
    } else {
      return 'An unexpected error occurred';
    }
  }
}