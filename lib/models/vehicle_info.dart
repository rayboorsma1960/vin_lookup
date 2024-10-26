// lib/models/vehicle_info.dart

class VehicleInfo {
  final String vin;
  final String make;
  final String model;
  final int year;
  final String vehicleType;
  final String engineSize;
  final String fuelType;
  final String transmission;
  final String driveType;
  final int doors;
  final String imageUrl;
  final List<Map<String, dynamic>> recalls;
  final Map<String, dynamic> safetyRatings;
  final List<Map<String, dynamic>> complaints;

  // Manufacturing Information
  final String manufacturerName;
  final String plantCity;
  final String plantState;
  final String plantCountry;
  final String vehicleDescriptor;
  final String bodyClass;
  final String steeringLocation;
  final String series;
  final String trim;

  // Engine Information
  final String? engineConfiguration;
  final String? engineCylinders;
  final String? engineHP;
  final String? engineModel;
  final String? engineManufacturer;
  final String? valveTrainDesign;
  final String? turbo;

  // EV Information
  final String? batteryType;
  final String? batteryKWh;
  final String? chargerLevel;
  final String? chargerPowerKW;
  final String? eVDriveUnit;
  final String? electrificationLevel;

  // Safety Features
  final String? adaptiveCruiseControl;
  final String? laneDepartureWarning;
  final String? blindSpotMon;
  final String? forwardCollisionWarning;
  final String? parkAssist;
  final String? rearCrossTrafficAlert;
  final String? automaticPedestrianAlertingSound;

  // Weight & Dimensions
  final String? curbWeightLB;
  final String? wheelBaseLong;
  final String? wheelBaseShort;
  final String? trackWidth;
  final String? wheelSizeFront;
  final String? wheelSizeRear;

  VehicleInfo({
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.engineSize,
    required this.fuelType,
    required this.transmission,
    required this.driveType,
    required this.doors,
    required this.imageUrl,
    this.recalls = const [],
    this.safetyRatings = const {},
    this.complaints = const [],
    required this.manufacturerName,
    required this.plantCity,
    required this.plantState,
    required this.plantCountry,
    required this.vehicleDescriptor,
    required this.bodyClass,
    required this.steeringLocation,
    required this.series,
    required this.trim,
    this.engineConfiguration,
    this.engineCylinders,
    this.engineHP,
    this.engineModel,
    this.engineManufacturer,
    this.valveTrainDesign,
    this.turbo,
    this.batteryType,
    this.batteryKWh,
    this.chargerLevel,
    this.chargerPowerKW,
    this.eVDriveUnit,
    this.electrificationLevel,
    this.adaptiveCruiseControl,
    this.laneDepartureWarning,
    this.blindSpotMon,
    this.forwardCollisionWarning,
    this.parkAssist,
    this.rearCrossTrafficAlert,
    this.automaticPedestrianAlertingSound,
    this.curbWeightLB,
    this.wheelBaseLong,
    this.wheelBaseShort,
    this.trackWidth,
    this.wheelSizeFront,
    this.wheelSizeRear,
  });

  // Factory constructor to create a VehicleInfo instance from JSON data
  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vin: json['VIN'] ?? '',
      make: json['Make'] ?? '',
      model: json['Model'] ?? '',
      year: int.tryParse(json['ModelYear'] ?? '') ?? 0,
      vehicleType: json['VehicleType'] ?? '',
      engineSize: json['DisplacementL'] ?? '',
      fuelType: json['FuelTypePrimary'] ?? '',
      transmission: json['TransmissionStyle'] ?? '',
      driveType: json['DriveType'] ?? '',
      doors: int.tryParse(json['Doors'] ?? '') ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      recalls: List<Map<String, dynamic>>.from(json['recalls'] ?? []),
      safetyRatings: Map<String, dynamic>.from(json['safetyRatings'] ?? {}),
      complaints: List<Map<String, dynamic>>.from(json['complaints'] ?? []),
      manufacturerName: json['Manufacturer'] ?? '',
      plantCity: json['PlantCity'] ?? '',
      plantState: json['PlantState'] ?? '',
      plantCountry: json['PlantCountry'] ?? '',
      vehicleDescriptor: json['VehicleDescriptor'] ?? '',
      bodyClass: json['BodyClass'] ?? '',
      steeringLocation: json['SteeringLocation'] ?? '',
      series: json['Series'] ?? '',
      trim: json['Trim'] ?? '',
      engineConfiguration: json['EngineConfiguration'],
      engineCylinders: json['EngineCylinders'],
      engineHP: json['EngineHP'],
      engineModel: json['EngineModel'],
      engineManufacturer: json['EngineManufacturer'],
      valveTrainDesign: json['ValveTrainDesign'],
      turbo: json['Turbo'],
      batteryType: json['BatteryType'],
      batteryKWh: json['BatteryKWh'],
      chargerLevel: json['ChargerLevel'],
      chargerPowerKW: json['ChargerPowerKW'],
      eVDriveUnit: json['EVDriveUnit'],
      electrificationLevel: json['ElectrificationLevel'],
      adaptiveCruiseControl: json['AdaptiveCruiseControl'],
      laneDepartureWarning: json['LaneDepartureWarning'],
      blindSpotMon: json['BlindSpotMon'],
      forwardCollisionWarning: json['ForwardCollisionWarning'],
      parkAssist: json['ParkAssist'],
      rearCrossTrafficAlert: json['RearCrossTrafficAlert'],
      automaticPedestrianAlertingSound: json['AutomaticPedestrianAlertingSound'],
      curbWeightLB: json['CurbWeightLB'],
      wheelBaseLong: json['WheelBaseLong'],
      wheelBaseShort: json['WheelBaseShort'],
      trackWidth: json['TrackWidth'],
      wheelSizeFront: json['WheelSizeFront'],
      wheelSizeRear: json['WheelSizeRear'],
    );
  }

  // Convert VehicleInfo instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'VIN': vin,
      'Make': make,
      'Model': model,
      'ModelYear': year.toString(),
      'VehicleType': vehicleType,
      'DisplacementL': engineSize,
      'FuelTypePrimary': fuelType,
      'TransmissionStyle': transmission,
      'DriveType': driveType,
      'Doors': doors.toString(),
      'imageUrl': imageUrl,
      'recalls': recalls,
      'safetyRatings': safetyRatings,
      'complaints': complaints,
      'Manufacturer': manufacturerName,
      'PlantCity': plantCity,
      'PlantState': plantState,
      'PlantCountry': plantCountry,
      'VehicleDescriptor': vehicleDescriptor,
      'BodyClass': bodyClass,
      'SteeringLocation': steeringLocation,
      'Series': series,
      'Trim': trim,
      'EngineConfiguration': engineConfiguration,
      'EngineCylinders': engineCylinders,
      'EngineHP': engineHP,
      'EngineModel': engineModel,
      'EngineManufacturer': engineManufacturer,
      'ValveTrainDesign': valveTrainDesign,
      'Turbo': turbo,
      'BatteryType': batteryType,
      'BatteryKWh': batteryKWh,
      'ChargerLevel': chargerLevel,
      'ChargerPowerKW': chargerPowerKW,
      'EVDriveUnit': eVDriveUnit,
      'ElectrificationLevel': electrificationLevel,
      'AdaptiveCruiseControl': adaptiveCruiseControl,
      'LaneDepartureWarning': laneDepartureWarning,
      'BlindSpotMon': blindSpotMon,
      'ForwardCollisionWarning': forwardCollisionWarning,
      'ParkAssist': parkAssist,
      'RearCrossTrafficAlert': rearCrossTrafficAlert,
      'AutomaticPedestrianAlertingSound': automaticPedestrianAlertingSound,
      'CurbWeightLB': curbWeightLB,
      'WheelBaseLong': wheelBaseLong,
      'WheelBaseShort': wheelBaseShort,
      'TrackWidth': trackWidth,
      'WheelSizeFront': wheelSizeFront,
      'WheelSizeRear': wheelSizeRear,
    };
  }

  // Copy with method for creating a new instance with some updated fields
  VehicleInfo copyWith({
    String? vin,
    String? make,
    String? model,
    int? year,
    String? vehicleType,
    String? engineSize,
    String? fuelType,
    String? transmission,
    String? driveType,
    int? doors,
    String? imageUrl,
    List<Map<String, dynamic>>? recalls,
    Map<String, dynamic>? safetyRatings,
    List<Map<String, dynamic>>? complaints,
    String? manufacturerName,
    String? plantCity,
    String? plantState,
    String? plantCountry,
    String? vehicleDescriptor,
    String? bodyClass,
    String? steeringLocation,
    String? series,
    String? trim,
    String? engineConfiguration,
    String? engineCylinders,
    String? engineHP,
    String? engineModel,
    String? engineManufacturer,
    String? valveTrainDesign,
    String? turbo,
    String? batteryType,
    String? batteryKWh,
    String? chargerLevel,
    String? chargerPowerKW,
    String? eVDriveUnit,
    String? electrificationLevel,
    String? adaptiveCruiseControl,
    String? laneDepartureWarning,
    String? blindSpotMon,
    String? forwardCollisionWarning,
    String? parkAssist,
    String? rearCrossTrafficAlert,
    String? automaticPedestrianAlertingSound,
    String? curbWeightLB,
    String? wheelBaseLong,
    String? wheelBaseShort,
    String? trackWidth,
    String? wheelSizeFront,
    String? wheelSizeRear,
  }) {
    return VehicleInfo(
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vehicleType: vehicleType ?? this.vehicleType,
      engineSize: engineSize ?? this.engineSize,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      driveType: driveType ?? this.driveType,
      doors: doors ?? this.doors,
      imageUrl: imageUrl ?? this.imageUrl,
      recalls: recalls ?? this.recalls,
      safetyRatings: safetyRatings ?? this.safetyRatings,
      complaints: complaints ?? this.complaints,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      plantCity: plantCity ?? this.plantCity,
      plantState: plantState ?? this.plantState,
      plantCountry: plantCountry ?? this.plantCountry,
      vehicleDescriptor: vehicleDescriptor ?? this.vehicleDescriptor,
      bodyClass: bodyClass ?? this.bodyClass,
      steeringLocation: steeringLocation ?? this.steeringLocation,
      series: series ?? this.series,
      trim: trim ?? this.trim,
      engineConfiguration: engineConfiguration ?? this.engineConfiguration,
      engineCylinders: engineCylinders ?? this.engineCylinders,
      engineHP: engineHP ?? this.engineHP,
      engineModel: engineModel ?? this.engineModel,
      engineManufacturer: engineManufacturer ?? this.engineManufacturer,
      valveTrainDesign: valveTrainDesign ?? this.valveTrainDesign,
      turbo: turbo ?? this.turbo,
      batteryType: batteryType ?? this.batteryType,
      batteryKWh: batteryKWh ?? this.batteryKWh,
      chargerLevel: chargerLevel ?? this.chargerLevel,
      chargerPowerKW: chargerPowerKW ?? this.chargerPowerKW,
      eVDriveUnit: eVDriveUnit ?? this.eVDriveUnit,
      electrificationLevel: electrificationLevel ?? this.electrificationLevel,
      adaptiveCruiseControl: adaptiveCruiseControl ?? this.adaptiveCruiseControl,
      laneDepartureWarning: laneDepartureWarning ?? this.laneDepartureWarning,
      blindSpotMon: blindSpotMon ?? this.blindSpotMon,
      forwardCollisionWarning: forwardCollisionWarning ?? this.forwardCollisionWarning,
      parkAssist: parkAssist ?? this.parkAssist,
      rearCrossTrafficAlert: rearCrossTrafficAlert ?? this.rearCrossTrafficAlert,
      automaticPedestrianAlertingSound: automaticPedestrianAlertingSound ?? this.automaticPedestrianAlertingSound,
      curbWeightLB: curbWeightLB ?? this.curbWeightLB,
      wheelBaseLong: wheelBaseLong ?? this.wheelBaseLong,
      wheelBaseShort: wheelBaseShort ?? this.wheelBaseShort,
      trackWidth: trackWidth ?? this.trackWidth,
      wheelSizeFront: wheelSizeFront ?? this.wheelSizeFront,
      wheelSizeRear: wheelSizeRear ?? this.wheelSizeRear,
    );
  }
}