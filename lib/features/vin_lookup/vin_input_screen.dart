import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../vehicle_details/vehicle_details_screen.dart';
import 'package:logging/logging.dart';

class VinInputScreen extends StatefulWidget {
  const VinInputScreen({super.key});

  @override
  State<VinInputScreen> createState() => _VinInputScreenState();
}

class _VinInputScreenState extends State<VinInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vinController = TextEditingController();
  final _log = Logger('VinInputScreen');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter VIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a VIN';
                  }
                  if (value.length != 17) {
                    return 'VIN must be 17 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitVin,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitVin() {
    if (_formKey.currentState!.validate()) {
      _log.info('Submitting VIN: ${_vinController.text}');
      final provider = Provider.of<VehicleInfoProvider>(context, listen: false);
      provider.fetchVehicleInfo(_vinController.text).then((_) {
        _log.info('Navigation to VehicleDetailsScreen');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VehicleDetailsScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }
}