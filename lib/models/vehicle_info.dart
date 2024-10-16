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
  // New fields from extended info
  final String manufacturerName;
  final String plantCity;
  final String plantState;
  final String plantCountry;
  final String vehicleDescriptor;
  final String bodyClass;
  final String steeringLocation;
  final String series;
  final String trim;

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
  });

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
    );
  }
}