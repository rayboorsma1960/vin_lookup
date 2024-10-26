// vehicle_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../../models/vehicle_info.dart';
import '../../models/app_exceptions.dart';
import 'package:logging/logging.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  static final _log = Logger('VehicleDetailsScreen');
  String? selectedRecallId;
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final provider = Provider.of<VehicleInfoProvider>(context, listen: false);
      if (provider.vehicleInfo != null) {
        await provider.fetchVehicleInfo(provider.vehicleInfo!.vin);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _shareVehicleInfo(VehicleInfo vehicleInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: 'Refresh vehicle information',
          ),
        ],
      ),
      body: Consumer<VehicleInfoProvider>(
        builder: (context, provider, child) {
          _log.info('Building VehicleDetailsScreen');
          _log.info('Provider state - isLoading: ${provider
              .isLoading}, error: ${provider.error}');

          if (provider.isLoading || _isRefreshing) {
            return _buildLoadingState();
          } else if (provider.error != null) {
            return _buildErrorState(provider);
          } else if (provider.vehicleInfo == null) {
            return _buildNoDataState();
          }

          return _buildContent(provider.vehicleInfo!);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading vehicle details...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VehicleInfoProvider provider) {
    String errorMessage = provider.getUserFriendlyError();
    bool isNetworkError = provider.error is NetworkException;
    bool isDataError = provider.error is DataParsingException;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError
                  ? Icons.cloud_off
                  : isDataError
                  ? Icons.data_object
                  : Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isNetworkError || isDataError) ...[
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.car_crash_outlined,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'No vehicle information available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try searching for your vehicle again',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('New Search'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(VehicleInfo vehicleInfo) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${vehicleInfo.year} ${vehicleInfo.make} ${vehicleInfo
                        .model}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareVehicleInfo(vehicleInfo),
                  tooltip: 'Share vehicle information',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'VIN: ${vehicleInfo.vin}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
                label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String label, String value) {
    final bool isAvailable = !['No', 'N/A', 'null', ''].contains(
        value.toLowerCase());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.remove_circle_outline,
            size: 20,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isAvailable ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(VehicleInfo vehicleInfo) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleHeader(vehicleInfo),
            const SizedBox(height: 20),
            _buildVehicleImage(vehicleInfo),
            const SizedBox(height: 20),
            _buildInfoSection('Vehicle Information', [
              _buildInfoTile('VIN', vehicleInfo.vin),
              _buildInfoTile(
                  'Make', '${vehicleInfo.make} (ID: ${vehicleInfo.makeId})'),
              _buildInfoTile(
                  'Model', '${vehicleInfo.model} (ID: ${vehicleInfo.modelId})'),
              _buildInfoTile('Year', vehicleInfo.year.toString()),
              _buildInfoTile('Vehicle Type', vehicleInfo.vehicleType),
              _buildInfoTile('Body Class', vehicleInfo.bodyClass),
              _buildInfoTile('Series', vehicleInfo.series),
              if (vehicleInfo.series2.isNotEmpty)
                _buildInfoTile('Series 2', vehicleInfo.series2),
              _buildInfoTile('Trim', vehicleInfo.trim),
              if (vehicleInfo.trim2.isNotEmpty)
                _buildInfoTile('Trim 2', vehicleInfo.trim2),
              _buildInfoTile('Doors', vehicleInfo.doors.toString()),
            ]),
            const SizedBox(height: 20),
            _buildInfoSection('Engine Information', [
              _buildInfoTile('Configuration', vehicleInfo.engineConfiguration),
              _buildInfoTile('Cylinders', vehicleInfo.engineCylinders),
              _buildInfoTile('Model', vehicleInfo.engineModel),
              _buildInfoTile('Manufacturer', vehicleInfo.engineManufacturer),
              _buildInfoTile(
                  'Displacement (CC)', vehicleInfo.engineDisplacementCC),
              _buildInfoTile(
                  'Displacement (CI)', vehicleInfo.engineDisplacementCI),
              _buildInfoTile(
                  'Displacement (L)', vehicleInfo.engineDisplacementL),
              _buildInfoTile('Horsepower', vehicleInfo.engineHP),
              _buildInfoTile('Power (kW)', vehicleInfo.engineKW),
              _buildInfoTile('Cycles', vehicleInfo.engineCycles),
              _buildInfoTile('Fuel Injection', vehicleInfo.fuelInjectionType),
              _buildInfoTile('Primary Fuel', vehicleInfo.fuelTypePrimary),
              if (vehicleInfo.fuelTypeSecondary.isNotEmpty)
                _buildInfoTile('Secondary Fuel', vehicleInfo.fuelTypeSecondary),
              if (vehicleInfo.otherEngineInfo.isNotEmpty)
                _buildInfoTile('Additional Info', vehicleInfo.otherEngineInfo),
              if (vehicleInfo.turbo.isNotEmpty)
                _buildInfoTile('Turbo', vehicleInfo.turbo),
            ]),
            const SizedBox(height: 20),
            _buildTransmissionDriveSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildDimensionsWeightSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildManufacturingSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildSafetyFeaturesSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildSafetyEquipmentSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildLightingSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildAdditionalFeaturesSection(vehicleInfo),
            const SizedBox(height: 20),
            _buildSafetyRatingsSection(vehicleInfo.safetyRatings),
            const SizedBox(height: 20),
            _buildRecallsSection(vehicleInfo.recalls),
          ],
        ),
      ),
    );
  }

  Widget _buildTransmissionDriveSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Transmission & Drive', [
      _buildInfoTile('Drive Type', vehicleInfo.driveType),
      _buildInfoTile('Transmission', vehicleInfo.transmissionStyle),
      if (vehicleInfo.transmissionSpeeds.isNotEmpty)
        _buildInfoTile('Speeds', vehicleInfo.transmissionSpeeds),
    ]);
  }

  Widget _buildDimensionsWeightSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Dimensions & Weight', [
      _buildInfoTile('Wheelbase Type', vehicleInfo.wheelBaseType),
      if (vehicleInfo.wheelBaseShort.isNotEmpty)
        _buildInfoTile('Wheelbase (Short)', vehicleInfo.wheelBaseShort),
      if (vehicleInfo.wheelBaseLong.isNotEmpty)
        _buildInfoTile('Wheelbase (Long)', vehicleInfo.wheelBaseLong),
      _buildInfoTile('Track Width', vehicleInfo.trackWidth),
      _buildInfoTile('Front Wheel Size', vehicleInfo.wheelSizeFront),
      _buildInfoTile('Rear Wheel Size', vehicleInfo.wheelSizeRear),
      _buildInfoTile('Curb Weight', vehicleInfo.curbWeightLB),
      _buildInfoTile('GVWR', vehicleInfo.gvwr),
      _buildInfoTile('GCWR', vehicleInfo.gcwr),
      if (vehicleInfo.bedLengthIN.isNotEmpty)
        _buildInfoTile('Bed Length', '${vehicleInfo.bedLengthIN} inches'),
      if (vehicleInfo.bedType.isNotEmpty)
        _buildInfoTile('Bed Type', vehicleInfo.bedType),
      if (vehicleInfo.bodyCabType.isNotEmpty)
        _buildInfoTile('Cab Type', vehicleInfo.bodyCabType),
    ]);
  }

  Widget _buildManufacturingSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Manufacturing Information', [
      _buildInfoTile('Manufacturer',
          '${vehicleInfo.manufacturerName} (ID: ${vehicleInfo
              .manufacturerId})'),
      _buildInfoTile('Plant Location',
          '${vehicleInfo.plantCity}, ${vehicleInfo.plantState}, ${vehicleInfo
              .plantCountry}'),
      if (vehicleInfo.plantCompanyName.isNotEmpty)
        _buildInfoTile('Plant Company', vehicleInfo.plantCompanyName),
      _buildInfoTile('Vehicle Descriptor', vehicleInfo.vehicleDescriptor),
    ]);
  }

  Widget _buildSafetyFeaturesSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Safety Features', [
      _buildFeatureTile('ABS', vehicleInfo.abs),
      _buildFeatureTile('Traction Control', vehicleInfo.traction),
      _buildFeatureTile('Stability Control', vehicleInfo.esc),
      _buildFeatureTile('Brake System', vehicleInfo.brakeSystemType),
      if (vehicleInfo.brakeSystemDesc.isNotEmpty)
        _buildInfoTile('Brake System Details', vehicleInfo.brakeSystemDesc),
      _buildFeatureTile(
          'Adaptive Cruise Control', vehicleInfo.adaptiveCruiseControl),
      _buildFeatureTile(
          'Lane Departure Warning', vehicleInfo.laneDepartureWarning),
      _buildFeatureTile('Lane Keep System', vehicleInfo.laneKeepSystem),
      _buildFeatureTile('Lane Centering', vehicleInfo.laneCenteringAssistance),
      _buildFeatureTile('Blind Spot Monitor', vehicleInfo.blindSpotMon),
      _buildFeatureTile(
          'Blind Spot Intervention', vehicleInfo.blindSpotIntervention),
      _buildFeatureTile(
          'Forward Collision Warning', vehicleInfo.forwardCollisionWarning),
      _buildFeatureTile(
          'Emergency Braking', vehicleInfo.automaticEmergencyBraking),
      _buildFeatureTile(
          'Rear Cross Traffic Alert', vehicleInfo.rearCrossTrafficAlert),
      _buildFeatureTile(
          'Rear Visibility System', vehicleInfo.rearVisibilitySystem),
      _buildFeatureTile('Park Assist', vehicleInfo.parkAssist),
      _buildFeatureTile('TPMS', vehicleInfo.tpms),
    ]);
  }

  Widget _buildSafetyEquipmentSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Safety Equipment', [
      _buildFeatureTile('Curtain Airbags', vehicleInfo.airBagLocCurtain),
      _buildFeatureTile('Front Airbags', vehicleInfo.airBagLocFront),
      _buildFeatureTile('Knee Airbags', vehicleInfo.airBagLocKnee),
      _buildFeatureTile(
          'Seat Cushion Airbags', vehicleInfo.airBagLocSeatCushion),
      _buildFeatureTile('Side Airbags', vehicleInfo.airBagLocSide),
      _buildFeatureTile('Pretensioner', vehicleInfo.pretensioner),
      _buildFeatureTile('Seat Belts', vehicleInfo.seatBeltsAll),
    ]);
  }

  Widget _buildLightingSection(VehicleInfo vehicleInfo) {
    return _buildInfoSection('Lighting', [
      _buildFeatureTile(
          'Daytime Running Lights', vehicleInfo.daytimeRunningLight),
      _buildFeatureTile('Adaptive Headlights', vehicleInfo.adaptiveHeadlights),
      _buildFeatureTile(
          'Adaptive Driving Beam', vehicleInfo.adaptiveDrivingBeam),
      if (vehicleInfo.headlampLightSource.isNotEmpty)
        _buildInfoTile(
            'Headlamp Light Source', vehicleInfo.headlampLightSource),
      _buildFeatureTile('Auto Headlamp Switching',
          vehicleInfo.semiautomaticHeadlampBeamSwitching),
    ]);
  }

  Widget _buildAdditionalFeaturesSection(VehicleInfo vehicleInfo) {
    final List<Widget> features = [];

    if (vehicleInfo.basePrice.isNotEmpty)
      features.add(_buildInfoTile('Base Price', vehicleInfo.basePrice));
    if (vehicleInfo.destinationMarket.isNotEmpty)
      features.add(_buildInfoTile('Market', vehicleInfo.destinationMarket));
    if (vehicleInfo.entertainmentSystem.isNotEmpty)
      features.add(
          _buildInfoTile('Entertainment', vehicleInfo.entertainmentSystem));
    if (vehicleInfo.keylessIgnition.isNotEmpty)
      features.add(
          _buildFeatureTile('Keyless Ignition', vehicleInfo.keylessIgnition));
    if (vehicleInfo.saeAutomationLevel.isNotEmpty)
      features.add(
          _buildInfoTile('Automation Level', vehicleInfo.saeAutomationLevel));

    return features.isEmpty ? const SizedBox.shrink() :
    _buildInfoSection('Additional Features', features);
  }

  Widget _buildVehicleImage(VehicleInfo vehicleInfo) {
    return Card(
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWithErrorHandling(vehicleInfo),
      ),
    );
  }

  Widget _buildImageWithErrorHandling(VehicleInfo vehicleInfo) {
    String? nhtsaImageUrl = vehicleInfo
        .safetyRatings['VehiclePicture'] as String?;
    String? googleImageUrl = vehicleInfo.imageUrl;

    if (nhtsaImageUrl == null && googleImageUrl.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.network(
          nhtsaImageUrl ?? googleImageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _log.warning('Failed to load NHTSA image: $error');
            if (nhtsaImageUrl != null && googleImageUrl.isNotEmpty) {
              return Image.network(
                googleImageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  _log.warning('Failed to load Google image: $error');
                  return _buildNoImagePlaceholder();
                },
              );
            }
            return _buildNoImagePlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_crash_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRatingsSection(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety Ratings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.safety_check,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No safety ratings available for this vehicle',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safety Ratings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSafetyRatings(ratings),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyRatings(Map<String, dynamic> ratings) {
    String? getRating(String key) {
      final value = ratings[key];
      if (value == null || value
          .toString()
          .trim()
          .isEmpty) {
        return null;
      }
      return value.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingTile('Overall Rating', getRating('OverallRating')),
        _buildDivider(),
        _buildRatingSection(
          'Crash Tests',
          [
            _buildRatingTile(
                'Frontal Crash', getRating('OverallFrontCrashRating')),
            _buildRatingTile('Side Crash', getRating('OverallSideCrashRating')),
            _buildRatingTile('Rollover', getRating('RolloverRating')),
          ],
        ),
        _buildDivider(),
        _buildRatingSection(
          'Detailed Crash Ratings',
          [
            _buildRatingTile('Front Crash Driver Side',
                getRating('FrontCrashDriversideRating')),
            _buildRatingTile('Front Crash Passenger Side',
                getRating('FrontCrashPassengersideRating')),
            _buildRatingTile('Side Crash Driver Side',
                getRating('SideCrashDriversideRating')),
            _buildRatingTile('Side Crash Passenger Side',
                getRating('SideCrashPassengersideRating')),
          ],
        ),
        const SizedBox(height: 16),
        _buildCrashTestImages(ratings),
      ],
    );
  }

  Widget _buildRatingSection(String title, List<Widget> ratings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...ratings,
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(),
    );
  }

  Widget _buildRatingTile(String label, String? rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: rating == null || rating == 'Not Rated'
                ? const Text(
              'Not Rated',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            )
                : _buildStarRating(int.tryParse(rating) ?? 0),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: [
        ...List.generate(
          5,
              (index) =>
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
        ),
        const SizedBox(width: 4),
        Text(
          '$rating/5',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCrashTestImages(Map<String, dynamic> ratings) {
    final frontImage = ratings['FrontCrashPicture'] as String?;
    final sideImage = ratings['SideCrashPicture'] as String?;

    if (frontImage == null && sideImage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crash Test Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (frontImage != null)
              Expanded(
                child: _buildCrashTestImage('Front Crash Test', frontImage),
              ),
            if (frontImage != null && sideImage != null)
              const SizedBox(width: 12),
            if (sideImage != null)
              Expanded(
                child: _buildCrashTestImage('Side Crash Test', sideImage),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCrashTestImage(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              _log.warning('Failed to load $title image: $error');
              return Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecallsSection(List<Map<String, dynamic>> recalls) {
    if (recalls.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recalls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 48,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No recalls found for this vehicle',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Recalls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${recalls.length} found',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecallsDropdown(recalls),
            if (selectedRecallId != null) _buildRecallDetails(recalls),
          ],
        ),
      ),
    );
  }

  Widget _buildRecallsDropdown(List<Map<String, dynamic>> recalls) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        hint: const Text('Select a Recall'),
        value: selectedRecallId,
        underline: const SizedBox(),
        items: recalls.map((recall) {
          final component = recall['Component'] ?? 'Unknown Component';
          final recallNumber = recall['NHTSACampaignNumber'];
          return DropdownMenuItem<String>(
            value: recallNumber,
            child: Text(
              'Recall $recallNumber: $component',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            selectedRecallId = value;
          });
        },
      ),
    );
  }

  Widget _buildRecallDetails(List<Map<String, dynamic>> recalls) {
    final selectedRecall = recalls.firstWhere(
          (recall) => recall['NHTSACampaignNumber'] == selectedRecallId,
      orElse: () => {},
    );

    if (selectedRecall.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecallDetailItem(
            'Recall Number',
            selectedRecall['NHTSACampaignNumber'],
            icon: Icons.numbers,
          ),
          _buildRecallDetailItem(
            'Component',
            selectedRecall['Component'],
            icon: Icons.build,
          ),
          _buildRecallDetailItem(
            'Summary',
            selectedRecall['Summary'],
            icon: Icons.description,
          ),
          _buildRecallDetailItem(
            'Consequence',
            selectedRecall['Conequence'],
            icon: Icons.warning,
          ),
          _buildRecallDetailItem(
            'Remedy',
            selectedRecall['Remedy'],
            icon: Icons.healing,
          ),
        ],
      ),
    );
  }

  Widget _buildRecallDetailItem(String label, String? value,
      {required IconData icon}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}