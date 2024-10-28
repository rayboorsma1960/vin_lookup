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
    } on AppException {
      rethrow;
    } catch (e) {
      _log.severe('Error in getVehicleInfo: $e');
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
              'The NHTSA service is temporarily unavailable (503)',
              isServerError: true,
              statusCode: 503,
            );
          case 404:
            throw ResourceNotFoundException(
              'Vehicle information not found',
              code: 'VIN_NOT_FOUND',
            );
          case 400:
            throw ValidationException(
              'Invalid VIN format or request',
              code: 'INVALID_VIN',
            );
          default:
            throw NetworkException(
              'Failed to load vehicle information (${response.statusCode})',
              isServerError: true,
              statusCode: response.statusCode,
            );
        }
      }

      final decodedResponse = json.decode(response.body);
      final results = decodedResponse['Results'][0] as Map<String, dynamic>;

      _log.info('Decoded VIN response: $results');

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
    } on NetworkException catch (e) {
      _log.severe('Network error in _getExtendedInfo: $e');
      rethrow;
    } catch (e) {
      _log.severe('Error in _getExtendedInfo: $e');
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

      _log.info('Fetching recalls from URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 503) {
        _log.warning('Recalls service is down (503)');
        return [];  // Return empty list instead of throwing for recalls
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log.info('Recalls API response: $data');

        if (data['Count'] > 0 && data['results'] is List) {
          final recalls = (data['results'] as List).cast<Map<String, dynamic>>();
          _log.info('Found ${recalls.length} recalls for $year $make $model');
          return recalls;
        }
        _log.info('No recalls found for $year $make $model');
      }

      _log.warning('Failed to fetch recalls. Status code: ${response.statusCode}');
      return [];
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

      if (response.statusCode == 503) {
        _log.warning('Vehicle variants service is down (503)');
        return [];  // Return empty list instead of throwing
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log.info('Vehicle variants API response: $data');

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

      if (response.statusCode == 503) {
        _log.warning('Safety ratings service is down (503)');
        return {};  // Return empty map instead of throwing
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Count'] > 0 && data['Results'] is List && data['Results'].isNotEmpty) {
          _log.info('Found safety ratings for vehicle ID: $vehicleId');
          return data['Results'][0];
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