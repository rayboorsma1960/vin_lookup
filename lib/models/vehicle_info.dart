// vehicle_info.dart

class VehicleInfo {
  final String vin;
  final String make;
  final String makeId;
  final String model;
  final String modelId;
  final int year;
  final String manufacturerId;
  final String manufacturerName;
  final String vehicleDescriptor;
  final String vehicleType;
  final String bodyClass;
  final String series;
  final String series2;
  final String trim;
  final String trim2;
  final String engineConfiguration;
  final String engineCylinders;
  final String engineModel;
  final String engineManufacturer;
  final String engineDisplacementCC;
  final String engineDisplacementCI;
  final String engineDisplacementL;
  final String engineHP;
  final String engineKW;
  final String engineCycles;
  final String fuelInjectionType;
  final String fuelTypePrimary;
  final String fuelTypeSecondary;
  final String otherEngineInfo;
  final String turbo;
  final String driveType;
  final String transmissionStyle;
  final String transmissionSpeeds;
  final int doors;
  final String wheelBaseType;
  final String wheelBaseShort;
  final String wheelBaseLong;
  final String trackWidth;
  final String wheelSizeFront;
  final String wheelSizeRear;
  final String curbWeightLB;
  final String gvwr;
  final String gcwr;
  final String gcwrTo;
  final String gvwrTo;
  final String bedLengthIN;
  final String bedType;
  final String bodyCabType;
  final String plantCity;
  final String plantState;
  final String plantCountry;
  final String plantCompanyName;
  final String abs;
  final String traction;
  final String esc;
  final String brakeSystemType;
  final String brakeSystemDesc;
  final String activeSafetySysNote;
  final String adaptiveCruiseControl;
  final String adaptiveHeadlights;
  final String adaptiveDrivingBeam;
  final String blindSpotMon;
  final String blindSpotIntervention;
  final String laneDepartureWarning;
  final String laneKeepSystem;
  final String laneCenteringAssistance;
  final String forwardCollisionWarning;
  final String automaticEmergencyBraking;
  final String rearCrossTrafficAlert;
  final String rearVisibilitySystem;
  final String parkAssist;
  final String tpms;
  final String airBagLocCurtain;
  final String airBagLocFront;
  final String airBagLocKnee;
  final String airBagLocSeatCushion;
  final String airBagLocSide;
  final String pretensioner;
  final String seatBeltsAll;
  final String daytimeRunningLight;
  final String headlampLightSource;
  final String semiautomaticHeadlampBeamSwitching;
  final String basePrice;
  final String destinationMarket;
  final String entertainmentSystem;
  final String keylessIgnition;
  final String saeAutomationLevel;
  final String imageUrl;
  final List<Map<String, dynamic>> recalls;
  final Map<String, dynamic> safetyRatings;
  final List<Map<String, dynamic>> complaints;

  VehicleInfo({
    required this.vin,
    required this.make,
    required this.makeId,
    required this.model,
    required this.modelId,
    required this.year,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.vehicleDescriptor,
    required this.vehicleType,
    required this.bodyClass,
    required this.series,
    required this.series2,
    required this.trim,
    required this.trim2,
    required this.engineConfiguration,
    required this.engineCylinders,
    required this.engineModel,
    required this.engineManufacturer,
    required this.engineDisplacementCC,
    required this.engineDisplacementCI,
    required this.engineDisplacementL,
    required this.engineHP,
    required this.engineKW,
    required this.engineCycles,
    required this.fuelInjectionType,
    required this.fuelTypePrimary,
    required this.fuelTypeSecondary,
    required this.otherEngineInfo,
    required this.turbo,
    required this.driveType,
    required this.transmissionStyle,
    required this.transmissionSpeeds,
    required this.doors,
    required this.wheelBaseType,
    required this.wheelBaseShort,
    required this.wheelBaseLong,
    required this.trackWidth,
    required this.wheelSizeFront,
    required this.wheelSizeRear,
    required this.curbWeightLB,
    required this.gvwr,
    required this.gcwr,
    required this.gcwrTo,
    required this.gvwrTo,
    required this.bedLengthIN,
    required this.bedType,
    required this.bodyCabType,
    required this.plantCity,
    required this.plantState,
    required this.plantCountry,
    required this.plantCompanyName,
    required this.abs,
    required this.traction,
    required this.esc,
    required this.brakeSystemType,
    required this.brakeSystemDesc,
    required this.activeSafetySysNote,
    required this.adaptiveCruiseControl,
    required this.adaptiveHeadlights,
    required this.adaptiveDrivingBeam,
    required this.blindSpotMon,
    required this.blindSpotIntervention,
    required this.laneDepartureWarning,
    required this.laneKeepSystem,
    required this.laneCenteringAssistance,
    required this.forwardCollisionWarning,
    required this.automaticEmergencyBraking,
    required this.rearCrossTrafficAlert,
    required this.rearVisibilitySystem,
    required this.parkAssist,
    required this.tpms,
    required this.airBagLocCurtain,
    required this.airBagLocFront,
    required this.airBagLocKnee,
    required this.airBagLocSeatCushion,
    required this.airBagLocSide,
    required this.pretensioner,
    required this.seatBeltsAll,
    required this.daytimeRunningLight,
    required this.headlampLightSource,
    required this.semiautomaticHeadlampBeamSwitching,
    required this.basePrice,
    required this.destinationMarket,
    required this.entertainmentSystem,
    required this.keylessIgnition,
    required this.saeAutomationLevel,
    required this.imageUrl,
    required this.recalls,
    required this.safetyRatings,
    required this.complaints,
  });

  // Add copyWith method
  VehicleInfo copyWith({
    String? vin,
    String? make,
    String? makeId,
    String? model,
    String? modelId,
    int? year,
    String? manufacturerId,
    String? manufacturerName,
    String? vehicleDescriptor,
    String? vehicleType,
    String? bodyClass,
    String? series,
    String? series2,
    String? trim,
    String? trim2,
    String? engineConfiguration,
    String? engineCylinders,
    String? engineModel,
    String? engineManufacturer,
    String? engineDisplacementCC,
    String? engineDisplacementCI,
    String? engineDisplacementL,
    String? engineHP,
    String? engineKW,
    String? engineCycles,
    String? fuelInjectionType,
    String? fuelTypePrimary,
    String? fuelTypeSecondary,
    String? otherEngineInfo,
    String? turbo,
    String? driveType,
    String? transmissionStyle,
    String? transmissionSpeeds,
    int? doors,
    String? wheelBaseType,
    String? wheelBaseShort,
    String? wheelBaseLong,
    String? trackWidth,
    String? wheelSizeFront,
    String? wheelSizeRear,
    String? curbWeightLB,
    String? gvwr,
    String? gcwr,
    String? gcwrTo,
    String? gvwrTo,
    String? bedLengthIN,
    String? bedType,
    String? bodyCabType,
    String? plantCity,
    String? plantState,
    String? plantCountry,
    String? plantCompanyName,
    String? abs,
    String? traction,
    String? esc,
    String? brakeSystemType,
    String? brakeSystemDesc,
    String? activeSafetySysNote,
    String? adaptiveCruiseControl,
    String? adaptiveHeadlights,
    String? adaptiveDrivingBeam,
    String? blindSpotMon,
    String? blindSpotIntervention,
    String? laneDepartureWarning,
    String? laneKeepSystem,
    String? laneCenteringAssistance,
    String? forwardCollisionWarning,
    String? automaticEmergencyBraking,
    String? rearCrossTrafficAlert,
    String? rearVisibilitySystem,
    String? parkAssist,
    String? tpms,
    String? airBagLocCurtain,
    String? airBagLocFront,
    String? airBagLocKnee,
    String? airBagLocSeatCushion,
    String? airBagLocSide,
    String? pretensioner,
    String? seatBeltsAll,
    String? daytimeRunningLight,
    String? headlampLightSource,
    String? semiautomaticHeadlampBeamSwitching,
    String? basePrice,
    String? destinationMarket,
    String? entertainmentSystem,
    String? keylessIgnition,
    String? saeAutomationLevel,
    String? imageUrl,
    List<Map<String, dynamic>>? recalls,
    Map<String, dynamic>? safetyRatings,
    List<Map<String, dynamic>>? complaints,
  }) {
    return VehicleInfo(
        vin: vin ?? this.vin,
        make: make ?? this.make,
        makeId: makeId ?? this.makeId,
        model: model ?? this.model,
        modelId: modelId ?? this.modelId,
        year: year ?? this.year,
        manufacturerId: manufacturerId ?? this.manufacturerId,
        manufacturerName: manufacturerName ?? this.manufacturerName,
        vehicleDescriptor: vehicleDescriptor ?? this.vehicleDescriptor,
        vehicleType: vehicleType ?? this.vehicleType,
        bodyClass: bodyClass ?? this.bodyClass,
        series: series ?? this.series,
        series2: series2 ?? this.series2,
        trim: trim ?? this.trim,
        trim2: trim2 ?? this.trim2,
        engineConfiguration: engineConfiguration ?? this.engineConfiguration,
        engineCylinders: engineCylinders ?? this.engineCylinders,
        engineModel: engineModel ?? this.engineModel,
        engineManufacturer: engineManufacturer ?? this.engineManufacturer,
        engineDisplacementCC: engineDisplacementCC ?? this.engineDisplacementCC,
        engineDisplacementCI: engineDisplacementCI ?? this.engineDisplacementCI,
        engineDisplacementL: engineDisplacementL ?? this.engineDisplacementL,
        engineHP: engineHP ?? this.engineHP,
        engineKW: engineKW ?? this.engineKW,
        engineCycles: engineCycles ?? this.engineCycles,
        fuelInjectionType: fuelInjectionType ?? this.fuelInjectionType,
        fuelTypePrimary: fuelTypePrimary ?? this.fuelTypePrimary,
        fuelTypeSecondary: fuelTypeSecondary ?? this.fuelTypeSecondary,
        otherEngineInfo: otherEngineInfo ?? this.otherEngineInfo,
        turbo: turbo ?? this.turbo,
        driveType: driveType ?? this.driveType,
        transmissionStyle: transmissionStyle ?? this.transmissionStyle,
        transmissionSpeeds: transmissionSpeeds ?? this.transmissionSpeeds,
        doors: doors ?? this.doors,
        wheelBaseType: wheelBaseType ?? this.wheelBaseType,
        wheelBaseShort: wheelBaseShort ?? this.wheelBaseShort,
        wheelBaseLong: wheelBaseLong ?? this.wheelBaseLong,
        trackWidth: trackWidth ?? this.trackWidth,
        wheelSizeFront: wheelSizeFront ?? this.wheelSizeFront,
        wheelSizeRear: wheelSizeRear ?? this.wheelSizeRear,
        curbWeightLB: curbWeightLB ?? this.curbWeightLB,
        gvwr: gvwr ?? this.gvwr,
        gcwr: gcwr ?? this.gcwr,
        gcwrTo: gcwrTo ?? this.gcwrTo,
        gvwrTo: gvwrTo ?? this.gvwrTo,
        bedLengthIN: bedLengthIN ?? this.bedLengthIN,
        bedType: bedType ?? this.bedType,
        bodyCabType: bodyCabType ?? this.bodyCabType,
        plantCity: plantCity ?? this.plantCity,
        plantState: plantState ?? this.plantState,
        plantCountry: plantCountry ?? this.plantCountry,
        plantCompanyName: plantCompanyName ?? this.plantCompanyName,
        abs: abs ?? this.abs,
        traction: traction ?? this.traction,
        esc: esc ?? this.esc,
        brakeSystemType: brakeSystemType ?? this.brakeSystemType,
        brakeSystemDesc: brakeSystemDesc ?? this.brakeSystemDesc,
        activeSafetySysNote: activeSafetySysNote ?? this.activeSafetySysNote,
        adaptiveCruiseControl: adaptiveCruiseControl ?? this.adaptiveCruiseControl,
        adaptiveHeadlights: adaptiveHeadlights ?? this.adaptiveHeadlights,
        adaptiveDrivingBeam: adaptiveDrivingBeam ?? this.adaptiveDrivingBeam,
        blindSpotMon: blindSpotMon ?? this.blindSpotMon,
        blindSpotIntervention: blindSpotIntervention ?? this.blindSpotIntervention,
        laneDepartureWarning: laneDepartureWarning ?? this.laneDepartureWarning,
        laneKeepSystem: laneKeepSystem ?? this.laneKeepSystem,
        laneCenteringAssistance: laneCenteringAssistance ?? this.laneCenteringAssistance,
        forwardCollisionWarning: forwardCollisionWarning ?? this.forwardCollisionWarning,
        automaticEmergencyBraking: automaticEmergencyBraking ?? this.automaticEmergencyBraking,
        rearCrossTrafficAlert: rearCrossTrafficAlert ?? this.rearCrossTrafficAlert,
        rearVisibilitySystem: rearVisibilitySystem ?? this.rearVisibilitySystem,
        parkAssist: parkAssist ?? this.parkAssist,
        tpms: tpms ?? this.tpms,
        airBagLocCurtain: airBagLocCurtain ?? this.airBagLocCurtain,
        airBagLocFront: airBagLocFront ?? this.airBagLocFront,
      airBagLocKnee: airBagLocKnee ?? this.airBagLocKnee,
      airBagLocSeatCushion: airBagLocSeatCushion ?? this.airBagLocSeatCushion,
      airBagLocSide: airBagLocSide ?? this.airBagLocSide,
      pretensioner: pretensioner ?? this.pretensioner,
      seatBeltsAll: seatBeltsAll ?? this.seatBeltsAll,
      daytimeRunningLight: daytimeRunningLight ?? this.daytimeRunningLight,
      headlampLightSource: headlampLightSource ?? this.headlampLightSource,
      semiautomaticHeadlampBeamSwitching: semiautomaticHeadlampBeamSwitching ?? this.semiautomaticHeadlampBeamSwitching,
      basePrice: basePrice ?? this.basePrice,
      destinationMarket: destinationMarket ?? this.destinationMarket,
      entertainmentSystem: entertainmentSystem ?? this.entertainmentSystem,
      keylessIgnition: keylessIgnition ?? this.keylessIgnition,
      saeAutomationLevel: saeAutomationLevel ?? this.saeAutomationLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      recalls: recalls ?? this.recalls,
      safetyRatings: safetyRatings ?? this.safetyRatings,
      complaints: complaints ?? this.complaints,
    );
  }

  @override
  String toString() {
    return 'VehicleInfo{'
        'vin: $vin, '
        'make: $make, '
        'model: $model, '
        'year: $year, '
        'trim: $trim}';  // Shortened for readability
  }
}