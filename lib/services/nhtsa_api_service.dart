import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_info.dart';
import '../models/app_exceptions.dart';
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
    } on NetworkException catch (e) {
      //_Log.severe('Network error in getVehicleInfo: $e');
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      //_Log.severe('Error in getVehicleInfo: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw NetworkException(
          'Unable to connect to the vehicle information service. Please check your internet connection.',
          isConnectivityError: true,
          originalError: e,
        );
      }
      throw VehicleInfoException(
        'Failed to retrieve vehicle information',
        vin: vin,
        originalError: e,
      );
    }
  }
  Future<VehicleInfo> _getExtendedInfo(String vin) async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}DecodeVinValuesExtended/$vin?format=json'));

      if (response.statusCode != 200) {
        switch (response.statusCode) {
          case 503:
            throw NetworkException(
              'The NHTSA vehicle information service is temporarily unavailable.',
              isServerError: true,
              statusCode: 503,
            );
          case 404:
            throw ResourceNotFoundException(
              'Vehicle information not found. Please verify the VIN and try again.',
              code: 'VIN_NOT_FOUND',
            );
          case 400:
            throw ValidationException(
              'Invalid VIN format. Please check the VIN and try again.',
              code: 'INVALID_VIN',
            );
          default:
            throw NetworkException(
              'The vehicle information service returned an unexpected response.',
              isServerError: true,
              statusCode: response.statusCode,
            );
        }
      }

      try {
        final decodedResponse = json.decode(response.body);
        final results = decodedResponse['Results']?[0] as Map<String, dynamic>?;

        if (results == null) {
          throw ValidationException(
            'Invalid response from the vehicle information service.',
            code: 'INVALID_RESPONSE',
          );
        }

        //_Log.info('Decoded VIN response successfully');

        return VehicleInfo(
          // Basic Vehicle Identification
          vin: vin,
          make: results['Make'] ?? 'N/A',
          makeId: results['MakeID'] ?? 'N/A',
          model: results['Model'] ?? 'N/A',
          modelId: results['ModelID'] ?? 'N/A',
          year: int.tryParse(results['ModelYear'] ?? '') ?? 0,
          manufacturerId: results['ManufacturerId'] ?? 'N/A',
          manufacturerName: results['Manufacturer'] ?? 'N/A',
          vehicleDescriptor: results['VehicleDescriptor'] ?? 'N/A',

          // Vehicle Classification
          vehicleType: results['VehicleType'] ?? 'N/A',
          bodyClass: results['BodyClass'] ?? 'N/A',
          series: results['Series'] ?? 'N/A',
          series2: results['Series2'] ?? 'N/A',
          trim: results['Trim'] ?? 'N/A',
          trim2: results['Trim2'] ?? 'N/A',

          // Engine Information
          engineConfiguration: results['EngineConfiguration'] ?? 'N/A',
          engineCylinders: results['EngineCylinders'] ?? 'N/A',
          engineModel: results['EngineModel'] ?? 'N/A',
          engineManufacturer: results['EngineManufacturer'] ?? 'N/A',
          engineDisplacementCC: results['DisplacementCC'] ?? 'N/A',
          engineDisplacementCI: results['DisplacementCI'] ?? 'N/A',
          engineDisplacementL: results['DisplacementL'] ?? 'N/A',
          engineHP: results['EngineHP'] ?? 'N/A',
          engineKW: results['EngineKW'] ?? 'N/A',
          engineCycles: results['EngineCycles'] ?? 'N/A',
          fuelInjectionType: results['FuelInjectionType'] ?? 'N/A',
          fuelTypePrimary: results['FuelTypePrimary'] ?? 'N/A',
          fuelTypeSecondary: results['FuelTypeSecondary'] ?? 'N/A',
          otherEngineInfo: results['OtherEngineInfo'] ?? 'N/A',
          turbo: results['Turbo'] ?? 'N/A',

          // Transmission & Drive
          driveType: results['DriveType'] ?? 'N/A',
          transmissionStyle: results['TransmissionStyle'] ?? 'N/A',
          transmissionSpeeds: results['TransmissionSpeeds'] ?? 'N/A',

          // Dimensions & Weight
          doors: int.tryParse(results['Doors'] ?? '') ?? 0,
          wheelBaseType: results['WheelBaseType'] ?? 'N/A',
          wheelBaseShort: results['WheelBaseShort'] ?? 'N/A',
          wheelBaseLong: results['WheelBaseLong'] ?? 'N/A',
          trackWidth: results['TrackWidth'] ?? 'N/A',
          wheelSizeFront: results['WheelSizeFront'] ?? 'N/A',
          wheelSizeRear: results['WheelSizeRear'] ?? 'N/A',
          curbWeightLB: results['CurbWeightLB'] ?? 'N/A',
          gvwr: results['GVWR'] ?? 'N/A',
          gcwr: results['GCWR'] ?? 'N/A',
          gcwrTo: results['GCWR_to'] ?? 'N/A',
          gvwrTo: results['GVWR_to'] ?? 'N/A',
          bedLengthIN: results['BedLengthIN'] ?? 'N/A',
          bedType: results['BedType'] ?? 'N/A',
          bodyCabType: results['BodyCabType'] ?? 'N/A',

          // Plant Information
          plantCity: results['PlantCity'] ?? 'N/A',
          plantState: results['PlantState'] ?? 'N/A',
          plantCountry: results['PlantCountry'] ?? 'N/A',
          plantCompanyName: results['PlantCompanyName'] ?? 'N/A',

          // Safety Features
          abs: results['ABS'] ?? 'N/A',
          traction: results['TractionControl'] ?? 'N/A',
          esc: results['ESC'] ?? 'N/A',
          brakeSystemType: results['BrakeSystemType'] ?? 'N/A',
          brakeSystemDesc: results['BrakeSystemDesc'] ?? 'N/A',
          activeSafetySysNote: results['ActiveSafetySysNote'] ?? 'N/A',
          adaptiveCruiseControl: results['AdaptiveCruiseControl'] ?? 'N/A',
          adaptiveHeadlights: results['AdaptiveHeadlights'] ?? 'N/A',
          adaptiveDrivingBeam: results['AdaptiveDrivingBeam'] ?? 'N/A',
          blindSpotMon: results['BlindSpotMon'] ?? 'N/A',
          blindSpotIntervention: results['BlindSpotIntervention'] ?? 'N/A',
          laneDepartureWarning: results['LaneDepartureWarning'] ?? 'N/A',
          laneKeepSystem: results['LaneKeepSystem'] ?? 'N/A',
          laneCenteringAssistance: results['LaneCenteringAssistance'] ?? 'N/A',
          forwardCollisionWarning: results['ForwardCollisionWarning'] ?? 'N/A',
          automaticEmergencyBraking: results['RearAutomaticEmergencyBraking'] ?? 'N/A',
          rearCrossTrafficAlert: results['RearCrossTrafficAlert'] ?? 'N/A',
          rearVisibilitySystem: results['RearVisibilitySystem'] ?? 'N/A',
          parkAssist: results['ParkAssist'] ?? 'N/A',
          tpms: results['TPMS'] ?? 'N/A',

          // Additional Safety Equipment
          airBagLocCurtain: results['AirBagLocCurtain'] ?? 'N/A',
          airBagLocFront: results['AirBagLocFront'] ?? 'N/A',
          airBagLocKnee: results['AirBagLocKnee'] ?? 'N/A',
          airBagLocSeatCushion: results['AirBagLocSeatCushion'] ?? 'N/A',
          airBagLocSide: results['AirBagLocSide'] ?? 'N/A',
          pretensioner: results['Pretensioner'] ?? 'N/A',
          seatBeltsAll: results['SeatBeltsAll'] ?? 'N/A',

          // Lighting
          daytimeRunningLight: results['DaytimeRunningLight'] ?? 'N/A',
          headlampLightSource: results['LowerBeamHeadlampLightSource'] ?? 'N/A',
          semiautomaticHeadlampBeamSwitching: results['SemiautomaticHeadlampBeamSwitching'] ?? 'N/A',

          // Price & Market
          basePrice: results['BasePrice'] ?? 'N/A',
          destinationMarket: results['DestinationMarket'] ?? 'N/A',

          // Additional Features
          entertainmentSystem: results['EntertainmentSystem'] ?? 'N/A',
          keylessIgnition: results['KeylessIgnition'] ?? 'N/A',
          saeAutomationLevel: results['SAEAutomationLevel'] ?? 'N/A',

          // API Related
          imageUrl: '',
          recalls: [],
          safetyRatings: {},
          complaints: [],
        );
      } on FormatException catch (e) {
        throw ValidationException(
          'Unable to process the vehicle information response.',
          code: 'INVALID_FORMAT',
          originalError: e,
        );
      }
    } catch (e) {
      //_Log.severe('Error in _getExtendedInfo: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw NetworkException(
          'Unable to connect to the vehicle information service. Please check your internet connection.',
          isConnectivityError: true,
          originalError: e,
        );
      } else if (e is NetworkException || e is ValidationException || e is ResourceNotFoundException) {
        rethrow;
      }
      throw VehicleInfoException(
        'Failed to process vehicle information',
        vin: vin,
        originalError: e,
      );
    }
  }
  Future<List<Map<String, dynamic>>> getRecalls(String make, String model, String year) async {
    try {
      final encodedMake = Uri.encodeComponent(make);
      final encodedModel = Uri.encodeComponent(model);
      final url = '$recallsUrl?make=$encodedMake&model=$encodedModel&modelYear=$year';

      //_Log.info('Fetching recalls from URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 503) {
        //_Log.warning('Recalls service is down (503)');
        return [];  // Return empty list instead of throwing for recalls
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          //_Log.info('Recalls API response: $data');

          if (data['Count'] > 0 && data['results'] is List) {
            final recalls = (data['results'] as List).cast<Map<String, dynamic>>();
            //_Log.info('Found ${recalls.length} recalls for $year $make $model');
            return recalls;
          }
          //_Log.info('No recalls found for $year $make $model');
        } on FormatException catch (e) {
          //_Log.warning('Error parsing recalls response: $e');
        }
      }

      //_Log.warning('Failed to fetch recalls. Status code: ${response.statusCode}');
      return [];
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        //_Log.warning('Network connectivity issue while fetching recalls: $e');
      } else {
        //_Log.severe('Error fetching recalls: $e');
      }
      return [];  // Return empty list for recalls errors to not block main flow
    }
  }

  Future<List<Map<String, dynamic>>> getVehicleVariants(String year, String make, String model) async {
    try {
      final encodedYear = Uri.encodeComponent(year);
      final encodedMake = Uri.encodeComponent(make);
      final encodedModel = Uri.encodeComponent(model);
      final url = '$safetyRatingsUrl/modelyear/$encodedYear/make/$encodedMake/model/$encodedModel?format=json';

      //_Log.info('Fetching vehicle variants from URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 503) {
        //_Log.warning('Vehicle variants service is down (503)');
        return [];  // Return empty list instead of throwing
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          //_Log.info('Vehicle variants API response: $data');

          if (data['Count'] > 0 && data['Results'] is List) {
            //_Log.info('Found ${data['Count']} vehicle variants');
            return List<Map<String, dynamic>>.from(data['Results']);
          }
        } on FormatException catch (e) {
          //_Log.warning('Error parsing vehicle variants response: $e');
        }
      }

      //_Log.warning('No vehicle variants found for $year $make $model');
      return [];
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        //_Log.warning('Network connectivity issue while fetching variants: $e');
      } else {
        //_Log.severe('Error fetching vehicle variants: $e');
      }
      return [];  // Return empty list for variants errors to not block main flow
    }
  }
  Future<Map<String, dynamic>> getSafetyRatings(String vehicleId) async {
    try {
      final url = '$safetyRatingsUrl/VehicleId/$vehicleId?format=json';
      //_Log.info('Fetching safety ratings from URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 503) {
        //_Log.warning('Safety ratings service is down (503)');
        return {};  // Return empty map instead of throwing
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['Count'] > 0 && data['Results'] is List && data['Results'].isNotEmpty) {
            //_Log.info('Found safety ratings for vehicle ID: $vehicleId');
            return data['Results'][0];
          }
        } on FormatException catch (e) {
          //_Log.warning('Error parsing safety ratings response: $e');
        }
      }

      //_Log.warning('No safety ratings found for vehicle ID: $vehicleId');
      return {};
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        //_Log.warning('Network connectivity issue while fetching safety ratings: $e');
      } else {
        //_Log.severe('Error fetching safety ratings: $e');
      }
      return {};  // Return empty map for safety ratings errors to not block main flow
    }
  }
}