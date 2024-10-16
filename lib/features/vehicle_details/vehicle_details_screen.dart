import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';

class VehicleDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vehicle Details')),
      body: Consumer<VehicleInfoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          } else if (provider.vehicleInfo == null) {
            return Center(child: Text('No vehicle information available'));
          } else {
            final vehicleInfo = provider.vehicleInfo!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicleInfo.imageUrl.isNotEmpty)
                    Center(
                      child: Image.network(vehicleInfo.imageUrl, height: 200),
                    ),
                  SizedBox(height: 20),
                  Text('Basic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  SizedBox(height: 20),
                  Text('Extended Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildInfoTile('Manufacturer', vehicleInfo.manufacturerName),
                  _buildInfoTile('Plant City', vehicleInfo.plantCity),
                  _buildInfoTile('Plant State', vehicleInfo.plantState),
                  _buildInfoTile('Plant Country', vehicleInfo.plantCountry),
                  _buildInfoTile('Vehicle Descriptor', vehicleInfo.vehicleDescriptor),
                  _buildInfoTile('Body Class', vehicleInfo.bodyClass),
                  _buildInfoTile('Steering Location', vehicleInfo.steeringLocation),
                  _buildInfoTile('Series', vehicleInfo.series),
                  _buildInfoTile('Trim', vehicleInfo.trim),
                  SizedBox(height: 20),
                  Text('Recalls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildRecallsList(vehicleInfo.recalls),
                  SizedBox(height: 20),
                  Text('Safety Ratings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildSafetyRatings(vehicleInfo.safetyRatings),
                  SizedBox(height: 20),
                  Text('Complaints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildComplaintsList(vehicleInfo.complaints),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRecallsList(List<Map<String, dynamic>> recalls) {
    if (recalls.isEmpty) {
      return Text('No recalls found for this vehicle.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recalls.length,
      itemBuilder: (context, index) {
        final recall = recalls[index];
        return ListTile(
          title: Text(recall['Component'] ?? 'Unknown Component'),
          subtitle: Text(recall['Summary'] ?? 'No summary available'),
        );
      },
    );
  }

  Widget _buildSafetyRatings(Map<String, dynamic> safetyRatings) {
    if (safetyRatings.isEmpty) {
      return Text('No safety ratings available for this vehicle.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: safetyRatings.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text('${entry.key}: ${entry.value}'),
        );
      }).toList(),
    );
  }

  Widget _buildComplaintsList(List<Map<String, dynamic>> complaints) {
    if (complaints.isEmpty) {
      return Text('No complaints found for this vehicle.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return ListTile(
          title: Text(complaint['Component'] ?? 'Unknown Component'),
          subtitle: Text(complaint['Summary'] ?? 'No summary available'),
        );
      },
    );
  }
}