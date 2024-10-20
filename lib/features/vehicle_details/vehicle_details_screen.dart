import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../../models/vehicle_info.dart';
import 'package:logging/logging.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({Key? key}) : super(key: key);

  @override
  _VehicleDetailsScreenState createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _log = Logger('VehicleDetailsScreen');
  String? selectedRecallId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: Consumer<VehicleInfoProvider>(
        builder: (context, provider, child) {
          _log.info('Building VehicleDetailsScreen');
          _log.info('Provider state - isLoading: ${provider.isLoading}, error: ${provider.error}');

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          } else if (provider.vehicleInfo == null) {
            return const Center(child: Text('No vehicle information available'));
          } else {
            final vehicleInfo = provider.vehicleInfo!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVehicleImage(vehicleInfo),
                  const SizedBox(height: 20),
                  _buildInfoSection('Basic Information', [
                    _buildInfoTile('VIN', vehicleInfo.vin),
                    _buildInfoTile('Make', vehicleInfo.make),
                    _buildInfoTile('Model', vehicleInfo.model),
                    _buildInfoTile('Year', vehicleInfo.year.toString()),
                    _buildInfoTile('Vehicle Type', vehicleInfo.vehicleType),
                    _buildInfoTile('Engine Size', vehicleInfo.engineSize),
                    _buildInfoTile('Fuel Type', vehicleInfo.fuelType),
                    _buildInfoTile('Transmission', vehicleInfo.transmission),
                    _buildInfoTile('Drive Type', vehicleInfo.driveType),
                    _buildInfoTile('Doors', vehicleInfo.doors.toString()),
                  ]),
                  const SizedBox(height: 20),
                  _buildInfoSection('Extended Information', [
                    _buildInfoTile('Manufacturer', vehicleInfo.manufacturerName),
                    _buildInfoTile('Plant City', vehicleInfo.plantCity),
                    _buildInfoTile('Plant State', vehicleInfo.plantState),
                    _buildInfoTile('Plant Country', vehicleInfo.plantCountry),
                    _buildInfoTile('Vehicle Descriptor', vehicleInfo.vehicleDescriptor),
                    _buildInfoTile('Body Class', vehicleInfo.bodyClass),
                    _buildInfoTile('Steering Location', vehicleInfo.steeringLocation),
                    _buildInfoTile('Series', vehicleInfo.series),
                    _buildInfoTile('Trim', vehicleInfo.trim),
                  ]),
                  const SizedBox(height: 20),
                  _buildVehicleVariantsSection(provider),
                  const SizedBox(height: 20),
                  _buildSafetyRatingsSection(vehicleInfo.safetyRatings),
                  const SizedBox(height: 20),
                  _buildRecallsSection(vehicleInfo.recalls),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildVehicleImage(VehicleInfo vehicleInfo) {
    String? nhtsaImageUrl = vehicleInfo.safetyRatings['VehiclePicture'] as String?;
    String? googleImageUrl = vehicleInfo.imageUrl;

    if (nhtsaImageUrl == null && googleImageUrl.isEmpty) {
      return const SizedBox.shrink(); // No image available
    }

    return Center(
      child: Image.network(
        nhtsaImageUrl ?? googleImageUrl,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          _log.warning('Failed to load NHTSA image: $error');
          if (nhtsaImageUrl != null && googleImageUrl.isNotEmpty) {
            // If NHTSA image fails, try Google image
            return Image.network(
              googleImageUrl,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                _log.warning('Failed to load Google image: $error');
                return const Placeholder(fallbackHeight: 200);
              },
            );
          }
          return const Placeholder(fallbackHeight: 200);
        },
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleVariantsSection(VehicleInfoProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Variants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildVehicleVariants(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleVariants(VehicleInfoProvider provider) {
    if (provider.vehicleVariants.isEmpty) {
      return const Text('No variants available');
    } else if (provider.vehicleVariants.length == 1) {
      return Text('Selected Variant: ${provider.vehicleVariants[0]['VehicleDescription']}');
    } else {
      return DropdownButton<String>(
        isExpanded: true,
        hint: const Text('Select Vehicle Variant'),
        value: provider.vehicleInfo?.safetyRatings.isNotEmpty == true
            ? provider.vehicleInfo!.safetyRatings['VehicleId'].toString()
            : null,
        items: provider.vehicleVariants.map((variant) {
          return DropdownMenuItem<String>(
            value: variant['VehicleId'].toString(),
            child: Text(
              variant['VehicleDescription'],
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? vehicleId) {
          if (vehicleId != null) {
            provider.selectVariantAndFetchSafetyRatings(vehicleId);
          }
        },
      );
    }
  }

  Widget _buildSafetyRatingsSection(Map<String, dynamic> ratings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safety Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSafetyRatings(ratings),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyRatings(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) {
      return const Text('No safety ratings available for this vehicle.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingTile('Overall Rating', ratings['OverallRating']),
        _buildRatingTile('Frontal Crash', ratings['OverallFrontCrashRating']),
        _buildRatingTile('Side Crash', ratings['OverallSideCrashRating']),
        _buildRatingTile('Rollover', ratings['RolloverRating']),
        _buildRatingTile('Front Crash Driver Side', ratings['FrontCrashDriversideRating']),
        _buildRatingTile('Front Crash Passenger Side', ratings['FrontCrashPassengersideRating']),
        _buildRatingTile('Side Crash Driver Side', ratings['SideCrashDriversideRating']),
        _buildRatingTile('Side Crash Passenger Side', ratings['SideCrashPassengersideRating']),
        const SizedBox(height: 16),
        _buildCrashTestImage('Front Crash Test', ratings['FrontCrashPicture']),
        _buildCrashTestImage('Side Crash Test', ratings['SideCrashPicture']),
      ],
    );
  }

  Widget _buildRatingTile(String label, String? rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: rating == null || rating == 'Not Rated'
                ? const Text('Not Rated', style: TextStyle(fontStyle: FontStyle.italic))
                : Row(
              children: List.generate(
                5,
                    (index) => Icon(
                  index < int.parse(rating) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashTestImage(String title, String? imageUrl) {
    if (imageUrl == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Image.network(
          imageUrl,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            _log.warning('Failed to load $title image: $error');
            return const Placeholder(fallbackHeight: 150);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRecallsSection(List<Map<String, dynamic>> recalls) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recalls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRecallsDropdown(recalls),
            if (selectedRecallId != null) _buildRecallDetails(recalls),
          ],
        ),
      ),
    );
  }

  Widget _buildRecallsDropdown(List<Map<String, dynamic>> recalls) {
    if (recalls.isEmpty) {
      return const Text('No recalls found for this vehicle.');
    }

    return DropdownButton<String>(
      isExpanded: true,
      hint: const Text('Select a Recall'),
      value: selectedRecallId,
      items: recalls.map((recall) {
        return DropdownMenuItem<String>(
          value: recall['NHTSACampaignNumber'],
          child: Text(
            'Recall ${recall['NHTSACampaignNumber']}: ${recall['Component']}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          selectedRecallId = value;
        });
      },
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

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recall Number: ${selectedRecall['NHTSACampaignNumber']}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Component: ${selectedRecall['Component']}'),
          const SizedBox(height: 8),
          Text('Summary: ${selectedRecall['Summary']}'),
          const SizedBox(height: 8),
          Text('Consequence: ${selectedRecall['Conequence']}'),
          const SizedBox(height: 8),
          Text('Remedy: ${selectedRecall['Remedy']}'),
        ],
      ),
    );
  }
}