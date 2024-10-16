import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_info.dart';
import 'package:logging/logging.dart';

class NHTSAApiService {
  final _log = Logger('NHTSAApiService');
  final String baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/';
  final String recallsUrl = 'https://api.nhtsa.gov/recalls/recallsByVehicle';
  final String safetyRatingsUrl = 'https://api.nhtsa.gov/SafetyRatings';
  final String complaintsUrl = 'https://api.nhtsa.gov/complaints/complaintsByVehicle';

  Future<VehicleInfo> getVehicleInfo(String vin) async {
    try {
      final basicInfo = await _getExtendedInfo(vin);
      final recalls = await _getRecalls(vin);
      final safetyRatings = await _getSafetyRatings(basicInfo.year.toString(), basicInfo.make, basicInfo.model);
      final complaints = await _getComplaints(basicInfo.year.toString(), basicInfo.make, basicInfo.model);

      return basicInfo.copyWith(
        recalls: recalls,
        safetyRatings: safetyRatings,
        complaints: complaints,
      );
    } catch (e) {
      _log.severe('Error in getVehicleInfo: $e');
      rethrow;
    }
  }

  Future<VehicleInfo> _getExtendedInfo(String vin) async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}DecodeVinValuesExtended/$vin?format=json'));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final results = decodedResponse['Results'][0] as Map<String, dynamic>;

        return VehicleInfo(
          vin: vin,
          make: results['Make'] ?? 'N/A',
          model: results['Model'] ?? 'N/A',
          year: int.tryParse(results['ModelYear'] ?? '') ?? 0,
          vehicleType: results['VehicleType'] ?? 'N/A',
          engineSize: results['EngineCylinders'] ?? 'N/A',
          fuelType: results['FuelTypePrimary'] ?? 'N/A',
          transmission: results['TransmissionStyle'] ?? 'N/A',
          driveType: results['DriveType'] ?? 'N/A',
          doors: int.tryParse(results['Doors'] ?? '') ?? 0,
          imageUrl: '',
          recalls: [],
          safetyRatings: {},
          complaints: [],
          // Add more fields as needed from the extended info
          manufacturerName: results['Manufacturer'] ?? 'N/A',
          plantCity: results['PlantCity'] ?? 'N/A',
          plantState: results['PlantState'] ?? 'N/A',
          plantCountry: results['PlantCountry'] ?? 'N/A',
          vehicleDescriptor: results['VehicleDescriptor'] ?? 'N/A',
          bodyClass: results['BodyClass'] ?? 'N/A',
          steeringLocation: results['SteeringLocation'] ?? 'N/A',
          series: results['Series'] ?? 'N/A',
          trim: results['Trim'] ?? 'N/A',
        );
      } else {
        throw Exception('Failed to load extended vehicle information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in _getExtendedInfo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getRecalls(String vin) async {
    try {
      final response = await http.get(Uri.parse('$recallsUrl?vin=$vin'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] == 0) {
          _log.info('No recalls found for VIN: $vin');
          return [];
        }
        return (data['results'] as List).cast<Map<String, dynamic>>();
      } else {
        _log.warning('Failed to fetch recalls. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _log.warning('Error fetching recalls: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getSafetyRatings(String year, String make, String model) async {
    try {
      final response = await http.get(Uri.parse('$safetyRatingsUrl/modelyear/$year/make/$make/model/$model'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] == 0) {
          _log.info('No safety ratings found for $year $make $model');
          return {};
        }
        return data['Results']?[0] ?? {};
      } else {
        _log.warning('Failed to fetch safety ratings. Status code: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      _log.warning('Error fetching safety ratings: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getComplaints(String year, String make, String model) async {
    try {
      final response = await http.get(Uri.parse('$complaintsUrl?year=$year&make=$make&model=$model'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] == 0) {
          _log.info('No complaints found for $year $make $model');
          return [];
        }
        return (data['results'] as List).cast<Map<String, dynamic>>();
      } else {
        _log.warning('Failed to fetch complaints. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _log.warning('Error fetching complaints: $e');
      return [];
    }
  }
}