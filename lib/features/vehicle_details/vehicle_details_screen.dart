// vehicle_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../../models/vehicle_info.dart';
import '../../models/app_exceptions.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;  // Add this line
import '../complaints/complaints_dashboard_screen.dart';
import '../recalls/recalls_dashboard_screen.dart';
// You can remove these imports since we're disabling video playback
// import 'dart:io';
// import '../../services/video_converter_service.dart';
// import '../../services/video_player_screen.dart';


// Add the StarRating widget here, BEFORE the VehicleDetailsScreen class:
class StarRating extends StatelessWidget {
  final dynamic rating;
  final double size;
  final Color filledColor;
  final Color unfilledColor;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18.0,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating.toString().toLowerCase() == 'not rated') {
      return Text(
        'Not Rated',
        style: TextStyle(
          fontSize: size,
          color: Colors.grey[600],
        ),
      );
    }

    final numericRating = double.tryParse(rating.toString()) ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < numericRating) {
          return Icon(
            Icons.star,
            size: size,
            color: filledColor,
          );
        } else if (index == numericRating.floor() &&
            numericRating % 1 != 0) {
          return Icon(
            Icons.star_half,
            size: size,
            color: filledColor,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: size,
            color: unfilledColor,
          );
        }
      }),
    );
  }
}


class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  static final _log = Logger('VehicleDetailsScreen');
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
          //_Log.info('Building VehicleDetailsScreen');

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
  // Helper methods for building info sections
  Widget _buildInfoSection(String title, List<Widget> children) {
    final nonEmptyChildren = children.where((child) => child is! SizedBox).toList();

    if (nonEmptyChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            ...nonEmptyChildren,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    if (value.isEmpty || value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'n/a' || value.toLowerCase() == 'not specified') {
      return const SizedBox.shrink();
    }

    // Check if this is a safety rating field
    final bool isSafetyRating = label.toLowerCase().contains('rating') ||
        label.toLowerCase().contains('crash');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: isSafetyRating
                ? StarRating(rating: value)
                : Text(value),
          ),
        ],
      ),
    );
  }


  Future<bool> _isVideoAvailable(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final response = await http.head(uri);
      return response.statusCode == 200;
    } catch (e) {
      //_Log.warning('Error checking video availability: $e');
      return false;
    }
  }

  // Updated method to disable video playback
  Widget _buildVideoLink(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    // Instead of making the link clickable, just show it as disabled text
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.videocam_off, // Changed to "video off" icon
            color: Colors.grey,  // Grey color indicates disabled
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label (Video playback temporarily unavailable)",
              style: const TextStyle(
                color: Colors.grey,  // Grey text for disabled state
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String label, String value) {
    if (['no', 'n/a', 'null', '', 'not specified', 'not available']
        .contains(value.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black),
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
                // Basic Vehicle Information
                _buildInfoSection('Vehicle Information', [
              _buildInfoTile('VIN', vehicleInfo.vin),
              _buildInfoTile('Year', vehicleInfo.year.toString()),
              _buildInfoTile('Make', vehicleInfo.make),
              _buildInfoTile('Make ID', vehicleInfo.makeId),
              _buildInfoTile('Model', vehicleInfo.model),
              _buildInfoTile('Model ID', vehicleInfo.modelId),
              _buildInfoTile('Vehicle Type', vehicleInfo.vehicleType),
              _buildInfoTile('Body Class', vehicleInfo.bodyClass),
              if (vehicleInfo.series.isNotEmpty)
                _buildInfoTile('Series', vehicleInfo.series),
              if (vehicleInfo.series2.isNotEmpty)
                _buildInfoTile('Series 2', vehicleInfo.series2),
              if (vehicleInfo.trim.isNotEmpty)
                _buildInfoTile('Trim', vehicleInfo.trim),
              if (vehicleInfo.trim2.isNotEmpty)
                _buildInfoTile('Trim 2', vehicleInfo.trim2),
              if (vehicleInfo.doors > 0)
                _buildInfoTile('Doors', vehicleInfo.doors.toString()),
            ]),

            const SizedBox(height: 20),

            // Vehicle Image Section
            Card(
              elevation: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (vehicleInfo.safetyRatings['VehiclePicture'] != null ||
                        vehicleInfo.imageUrl.isNotEmpty)
                      Image.network(
                        vehicleInfo.safetyRatings['VehiclePicture'] ?? vehicleInfo.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          //_Log.warning('Failed to load NHTSA image: $error');
                          if (vehicleInfo.safetyRatings['VehiclePicture'] != null &&
                              vehicleInfo.imageUrl.isNotEmpty) {
                            return Image.network(
                              vehicleInfo.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                //_Log.warning('Failed to load Google image: $error');
                                return _buildNoImagePlaceholder();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildImageLoadingIndicator(loadingProgress);
                              },
                            );
                          }
                          return _buildNoImagePlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImageLoadingIndicator(loadingProgress);
                        },
                      )
                    else
                      _buildNoImagePlaceholder(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),



            // Manufacturing Information
            _buildInfoSection('Manufacturing Information', [
              _buildInfoTile('Manufacturer', vehicleInfo.manufacturerName),
              _buildInfoTile('Manufacturer ID', vehicleInfo.manufacturerId),
              _buildInfoTile('Plant Location',
                  '${vehicleInfo.plantCity}, ${vehicleInfo.plantState}, ${vehicleInfo.plantCountry}'),
              if (vehicleInfo.plantCompanyName.isNotEmpty)
                _buildInfoTile('Plant Company', vehicleInfo.plantCompanyName),
              _buildInfoTile('Vehicle Descriptor', vehicleInfo.vehicleDescriptor),
            ]),

            const SizedBox(height: 20),

            // Engine Information
            _buildInfoSection('Engine Information', [
              _buildInfoTile('Configuration', vehicleInfo.engineConfiguration),
              _buildInfoTile('Cylinders', vehicleInfo.engineCylinders),
              _buildInfoTile('Engine Model', vehicleInfo.engineModel),
              _buildInfoTile('Manufacturer', vehicleInfo.engineManufacturer),
              _buildInfoTile('Displacement (CC)', vehicleInfo.engineDisplacementCC),
              _buildInfoTile('Displacement (CI)', vehicleInfo.engineDisplacementCI),
              _buildInfoTile('Displacement (L)', vehicleInfo.engineDisplacementL),
              _buildInfoTile('Horsepower', vehicleInfo.engineHP),
              _buildInfoTile('Power (kW)', vehicleInfo.engineKW),
              _buildInfoTile('Cycles', vehicleInfo.engineCycles),
              _buildInfoTile('Fuel Injection Type', vehicleInfo.fuelInjectionType),
              _buildInfoTile('Primary Fuel', vehicleInfo.fuelTypePrimary),
              if (vehicleInfo.fuelTypeSecondary.isNotEmpty)
                _buildInfoTile('Secondary Fuel', vehicleInfo.fuelTypeSecondary),
              if (vehicleInfo.otherEngineInfo.isNotEmpty)
                _buildInfoTile('Additional Info', vehicleInfo.otherEngineInfo),
              if (vehicleInfo.turbo.isNotEmpty)
                _buildInfoTile('Turbo', vehicleInfo.turbo),
            ]),

            const SizedBox(height: 20),

            // Transmission & Drive
            _buildInfoSection('Transmission & Drive', [
              _buildInfoTile('Drive Type', vehicleInfo.driveType),
              _buildInfoTile('Transmission Style', vehicleInfo.transmissionStyle),
              _buildInfoTile('Transmission Speeds', vehicleInfo.transmissionSpeeds),
            ]),

            const SizedBox(height: 20),

            // Dimensions & Weight
            _buildInfoSection('Dimensions & Weight', [
              _buildInfoTile('Wheelbase Type', vehicleInfo.wheelBaseType),
              if (vehicleInfo.wheelBaseShort.isNotEmpty)
                _buildInfoTile('Wheelbase (Short)', vehicleInfo.wheelBaseShort),
              if (vehicleInfo.wheelBaseLong.isNotEmpty)
                _buildInfoTile('Wheelbase (Long)', vehicleInfo.wheelBaseLong),
              _buildInfoTile('Track Width', vehicleInfo.trackWidth),
              _buildInfoTile('Front Wheel Size', vehicleInfo.wheelSizeFront),
              _buildInfoTile('Rear Wheel Size', vehicleInfo.wheelSizeRear),
              _buildInfoTile('Curb Weight (LB)', vehicleInfo.curbWeightLB),
              _buildInfoTile('GVWR', vehicleInfo.gvwr),
              _buildInfoTile('GCWR', vehicleInfo.gcwr),
              if (vehicleInfo.bedLengthIN.isNotEmpty)
                _buildInfoTile('Bed Length (IN)', vehicleInfo.bedLengthIN),
              if (vehicleInfo.bedType.isNotEmpty)
                _buildInfoTile('Bed Type', vehicleInfo.bedType),
              if (vehicleInfo.bodyCabType.isNotEmpty)
                _buildInfoTile('Cab Type', vehicleInfo.bodyCabType),
            ]),

            const SizedBox(height: 20),

            // Safety Features
            _buildInfoSection('Safety Features', [
              _buildFeatureTile('ABS', vehicleInfo.abs),
              _buildFeatureTile('Traction Control', vehicleInfo.traction),
              _buildFeatureTile('Stability Control', vehicleInfo.esc),
              _buildInfoTile('Brake System Type', vehicleInfo.brakeSystemType),
              if (vehicleInfo.brakeSystemDesc.isNotEmpty)
                _buildInfoTile('Brake System Details', vehicleInfo.brakeSystemDesc),
              _buildFeatureTile('Adaptive Cruise Control', vehicleInfo.adaptiveCruiseControl),
              _buildFeatureTile('Lane Departure Warning', vehicleInfo.laneDepartureWarning),
              _buildFeatureTile('Lane Keep System', vehicleInfo.laneKeepSystem),
              _buildFeatureTile('Lane Centering', vehicleInfo.laneCenteringAssistance),
              _buildFeatureTile('Blind Spot Monitor', vehicleInfo.blindSpotMon),
              _buildFeatureTile('Blind Spot Intervention', vehicleInfo.blindSpotIntervention),
              _buildFeatureTile('Forward Collision Warning', vehicleInfo.forwardCollisionWarning),
              _buildFeatureTile('Emergency Braking', vehicleInfo.automaticEmergencyBraking),
              _buildFeatureTile('Rear Cross Traffic Alert', vehicleInfo.rearCrossTrafficAlert),
              _buildFeatureTile('Rear Visibility System', vehicleInfo.rearVisibilitySystem),
              _buildFeatureTile('Park Assist', vehicleInfo.parkAssist),
              _buildFeatureTile('TPMS', vehicleInfo.tpms),
            ]),

            const SizedBox(height: 20),

            // Safety Equipment
            _buildInfoSection('Safety Equipment', [
              _buildFeatureTile('Curtain Airbags', vehicleInfo.airBagLocCurtain),
              _buildFeatureTile('Front Airbags', vehicleInfo.airBagLocFront),
              _buildFeatureTile('Knee Airbags', vehicleInfo.airBagLocKnee),
              _buildFeatureTile('Seat Cushion Airbags', vehicleInfo.airBagLocSeatCushion),
              _buildFeatureTile('Side Airbags', vehicleInfo.airBagLocSide),
              _buildFeatureTile('Pretensioner', vehicleInfo.pretensioner),
              _buildFeatureTile('Seat Belts', vehicleInfo.seatBeltsAll),
            ]),

            const SizedBox(height: 20),

            // Lighting
            _buildInfoSection('Lighting', [
              _buildFeatureTile('Daytime Running Lights', vehicleInfo.daytimeRunningLight),
              _buildFeatureTile('Adaptive Headlights', vehicleInfo.adaptiveHeadlights),
              _buildFeatureTile('Adaptive Driving Beam', vehicleInfo.adaptiveDrivingBeam),
              if (vehicleInfo.headlampLightSource.isNotEmpty)
                _buildInfoTile('Headlamp Light Source', vehicleInfo.headlampLightSource),
              _buildFeatureTile('Auto Headlamp Switching',
                  vehicleInfo.semiautomaticHeadlampBeamSwitching),
            ]),

            const SizedBox(height: 20),

            // Additional Features
            _buildInfoSection('Additional Features', [
              if (vehicleInfo.basePrice.isNotEmpty)
                _buildInfoTile('Base Price', vehicleInfo.basePrice),
              if (vehicleInfo.destinationMarket.isNotEmpty)
                _buildInfoTile('Market', vehicleInfo.destinationMarket),
              if (vehicleInfo.entertainmentSystem.isNotEmpty)
                _buildInfoTile('Entertainment System', vehicleInfo.entertainmentSystem),
              _buildFeatureTile('Keyless Ignition', vehicleInfo.keylessIgnition),
              if (vehicleInfo.saeAutomationLevel.isNotEmpty)
                _buildInfoTile('SAE Automation Level', vehicleInfo.saeAutomationLevel),
            ]),

            const SizedBox(height: 20),



            // Safety Ratings
            // Safety Ratings with Images
            // Safety Ratings
            if (vehicleInfo.safetyRatings.isNotEmpty)
        _buildInfoSection('Safety Ratings', [
      // Rating Information
      ...vehicleInfo.safetyRatings.entries
          .where((entry) =>
      entry.value != null &&
          entry.value.toString().isNotEmpty &&
          !entry.key.contains('Picture') &&
          !entry.key.contains('Video')) // Exclude picture and video URLs from text display
          .map((entry) => _buildInfoTile(
          entry.key.replaceAllMapped(
              RegExp(r'([A-Z])'),
                  (match) => ' ${match.group(1)}'
          ).trim(),
          entry.value.toString()
      )),

      // Video Links - these are now disabled
      if (vehicleInfo.safetyRatings['FrontCrashVideo'] != null)
        _buildVideoLink(
          'Watch Front Crash Test Video',
          vehicleInfo.safetyRatings['FrontCrashVideo'],
        ),
      if (vehicleInfo.safetyRatings['SideCrashVideo'] != null)
        _buildVideoLink(
          'Watch Side Crash Test Video',
          vehicleInfo.safetyRatings['SideCrashVideo'],
        ),

      // Crash Test Images
      const SizedBox(height: 16),
      if (vehicleInfo.safetyRatings['FrontCrashPicture'] != null ||
          vehicleInfo.safetyRatings['SideCrashPicture'] != null)
        Column(
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
                if (vehicleInfo.safetyRatings['FrontCrashPicture'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Front Crash Test',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            vehicleInfo.safetyRatings['FrontCrashPicture']!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              //_Log.warning('Failed to load front crash image: $error');
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
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                if (vehicleInfo.safetyRatings['FrontCrashPicture'] != null &&
                    vehicleInfo.safetyRatings['SideCrashPicture'] != null)
                  const SizedBox(width: 12),

                if (vehicleInfo.safetyRatings['SideCrashPicture'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Side Crash Test',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            vehicleInfo.safetyRatings['SideCrashPicture']!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              //_Log.warning('Failed to load side crash image: $error');
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
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
    ]),

    // In the _buildContent method of vehicle_details_screen.dart
    Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.red.shade50, Colors.orange.shade50],
    ),
    border: Border.all(color: Colors.red.shade200),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.1),
    spreadRadius: 1,
    blurRadius: 4,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    child: Card(
    elevation: 0,
    color: Colors.transparent,
    margin: EdgeInsets.zero,
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Wrapping header row in Expanded
    Row(
    children: [
    Container(
    decoration: BoxDecoration(
    color: Colors.red.shade100,
    shape: BoxShape.circle,
    ),
    padding: const EdgeInsets.all(8),
    child: Icon(Icons.warning_amber_rounded,
    color: Colors.red.shade700,
    size: 24
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Flexible(
    child: Text(
    'Vehicle Complaints Dashboard',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.red.shade900,
    ),
    overflow: TextOverflow.ellipsis,
    ),
    ),
    const SizedBox(width: 8),
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4
    ),
    decoration: BoxDecoration(
    color: Colors.red.shade100,
    borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
    '${vehicleInfo.complaints.length} Complaints',
    style: TextStyle(
    color: Colors.red.shade700,
    fontWeight: FontWeight.bold,
    fontSize: 13,
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    const SizedBox(height: 12),
    // Feature highlights with Flexible
    Row(
    children: [
    Flexible(
    child: Row(
    children: [
    Icon(Icons.trending_up,
    size: 16,
    color: Colors.red.shade600
    ),
    const SizedBox(width: 4),
      Flexible(
        child: Text(
          'Trend Analysis',
          style: TextStyle(
            fontSize: 13,
            color: Colors.red.shade800,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
    ),
    ),
      const SizedBox(width: 16),
      Flexible(
        child: Row(
          children: [
            Icon(Icons.message_outlined,
                size: 16,
                color: Colors.red.shade600
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Detailed Reports',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
    ),
      const SizedBox(height: 12),
      Text(
        'Access comprehensive complaint insights, safety analysis, and reported issues to make informed decisions about your vehicle.',
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintsDashboardScreen(
                make: vehicleInfo.make,
                model: vehicleInfo.model,
                year: vehicleInfo.year,
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'View Dashboard',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    ],
    ),
    ),
    ),
    ),

                  if (vehicleInfo.recalls.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.car_crash, color: Colors.orange.shade700, size: 24),
                          ),
                          title: Text(
                            'View Vehicle Recalls (${vehicleInfo.recalls.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          subtitle: Text(
                            'Review safety recalls and campaigns',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecallsDashboardScreen(
                                  recalls: vehicleInfo.recalls,
                                  make: vehicleInfo.make,
                                  model: vehicleInfo.model,
                                  year: vehicleInfo.year,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
            ),
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
    String errorMessage;
    IconData errorIcon;
    Color errorColor;

    if (provider.error is NetworkException) {
      final networkError = provider.error as NetworkException;
      if (networkError.isConnectivityError) {
        errorMessage = 'Unable to connect to the vehicle information service.\n\n'
            'Please check your internet connection and try again.';
        errorIcon = Icons.signal_wifi_off;
        errorColor = Colors.red;
      } else if (networkError.statusCode == 503) {
        errorMessage = 'The NHTSA vehicle information service is currently down. '
            'This is a temporary issue with the government database service, '
            'not with your app or internet connection.\n\n'
            'Please try again later.';
        errorIcon = Icons.cloud_off;
        errorColor = Colors.orange;
      } else if (networkError.isServerError) {
        errorMessage = 'Service is temporarily unavailable. Please try again later.';
        errorIcon = Icons.cloud_off;
        errorColor = Colors.orange;
      } else {
        errorMessage = 'Unable to process your request. Please try again.';
        errorIcon = Icons.error_outline;
        errorColor = Colors.red;
      }
    } else {
      errorMessage = provider.getUserFriendlyError();
      errorIcon = Icons.error_outline;
      errorColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  errorIcon,
                  size: 64,
                  color: errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _handleRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Try Again'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 16),
          const Text(
            'No vehicle information available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
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

  Widget _buildImageLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}