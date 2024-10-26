import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_info.dart';
import 'package:logging/logging.dart';

class NHTSAApiService {
  final _log = Logger('NHTSAApiService');
  final String baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/';
  final String recallsUrl = 'https://api.nhtsa.gov/recalls/recallsByVehicle';
  final String safetyRatingsUrl = 'https://api.nhtsa.gov/SafetyRatings';

  Future<VehicleInfo> getVehicleInfo(String vin) async {
    try {
      final basicInfo = await _getExtendedInfo(vin);
      final recalls = await getRecalls(basicInfo.make, basicInfo.model, basicInfo.year.toString());
      return basicInfo.copyWith(recalls: recalls);
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
          manufacturerName: results['Manufacturer'] ?? 'N/A',
          plantCity: results['PlantCity'] ?? 'N/A',
          plantState: results['PlantState'] ?? 'N/A',
          plantCountry: results['PlantCountry'] ?? 'N/A',
          vehicleDescriptor: results['VehicleDescriptor'] ?? 'N/A',
          bodyClass: results['BodyClass'] ?? 'N/A',
          steeringLocation: results['SteeringLocation'] ?? 'N/A',
          series: results['Series'] ?? 'N/A',
          trim: results['Trim'] ?? 'N/A',
          // New fields
          engineConfiguration: results['EngineConfiguration'],
          engineCylinders: results['EngineCylinders'],
          engineHP: results['EngineHP'],
          engineModel: results['EngineModel'],
          engineManufacturer: results['EngineManufacturer'],
          valveTrainDesign: results['ValveTrainDesign'],
          turbo: results['Turbo'],
          batteryType: results['BatteryType'],
          batteryKWh: results['BatteryKWh'],
          chargerLevel: results['ChargerLevel'],
          chargerPowerKW: results['ChargerPowerKW'],
          eVDriveUnit: results['EVDriveUnit'],
          electrificationLevel: results['ElectrificationLevel'],
          adaptiveCruiseControl: results['AdaptiveCruiseControl'],
          laneDepartureWarning: results['LaneDepartureWarning'],
          blindSpotMon: results['BlindSpotMon'],
          forwardCollisionWarning: results['ForwardCollisionWarning'],
          parkAssist: results['ParkAssist'],
          rearCrossTrafficAlert: results['RearCrossTrafficAlert'],
          automaticPedestrianAlertingSound: results['AutomaticPedestrianAlertingSound'],
          curbWeightLB: results['CurbWeightLB'],
          wheelBaseLong: results['WheelBaseLong'],
          wheelBaseShort: results['WheelBaseShort'],
          trackWidth: results['TrackWidth'],
          wheelSizeFront: results['WheelSizeFront'],
          wheelSizeRear: results['WheelSizeRear'],
        );
      } else {
        throw Exception('Failed to load extended vehicle information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in _getExtendedInfo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecalls(String make, String model, String year) async {
    try {
      final encodedMake = Uri.encodeComponent(make);
      final encodedModel = Uri.encodeComponent(model);
      final url = '$recallsUrl?make=$encodedMake&model=$encodedModel&modelYear=$year';

      _log.info('Fetching recalls from URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log.info('Recalls API response: $data');

        if (data['Count'] > 0 && data['results'] is List) {
          final recalls = (data['results'] as List).cast<Map<String, dynamic>>();
          _log.info('Found ${recalls.length} recalls for $year $make $model');
          return recalls;
        } else {
          _log.info('No recalls found for $year $make $model');
          return [];
        }
      } else {
        _log.warning('Failed to fetch recalls. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _log.severe('Error fetching recalls: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVehicleVariants(String year, String make, String model) async {
    try {
      final encodedYear = Uri.encodeComponent(year);
      final encodedMake = Uri.encodeComponent(make);
      final encodedModel = Uri.encodeComponent(model);
      final url = '$safetyRatingsUrl/modelyear/$encodedYear/make/$encodedMake/model/$encodedModel?format=json';

      _log.info('Fetching vehicle variants from URL: $url');

      final response = await http.get(Uri.parse(url));
      _log.info('Vehicle variants API response status code: ${response.statusCode}');
      _log.info('Vehicle variants API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] > 0 && data['Results'] is List) {
          _log.info('Found ${data['Count']} vehicle variants');
          return List<Map<String, dynamic>>.from(data['Results']);
        }
      }

      _log.warning('No vehicle variants found for $year $make $model');
      return [];
    } catch (e) {
      _log.severe('Error fetching vehicle variants: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSafetyRatings(String vehicleId) async {
    try {
      final url = '$safetyRatingsUrl/VehicleId/$vehicleId?format=json';
      _log.info('Fetching safety ratings from URL: $url');

      final response = await http.get(Uri.parse(url));
      _log.info('Safety Ratings API response status code: ${response.statusCode}');
      _log.info('Safety Ratings API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] > 0 && data['Results'] is List && data['Results'].isNotEmpty) {
          _log.info('Found safety ratings for vehicle ID: $vehicleId');
          return data['Results'][0];  // Return the entire Results object
        }
      }

      _log.warning('No safety ratings found for vehicle ID: $vehicleId');
      return {};
    } catch (e) {
      _log.severe('Error fetching safety ratings: $e');
      return {};
    }
  }
}