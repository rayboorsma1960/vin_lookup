import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../vehicle_details/vehicle_details_screen.dart';
import 'package:logging/logging.dart';

class VehicleVariantSelectionScreen extends StatefulWidget {
  static final _log = Logger('VehicleVariantSelectionScreen');

  const VehicleVariantSelectionScreen({super.key});

  @override
  State<VehicleVariantSelectionScreen> createState() => _VehicleVariantSelectionScreenState();
}

class _VehicleVariantSelectionScreenState extends State<VehicleVariantSelectionScreen> {
  bool _isLoading = false;
  static final _log = Logger('VehicleVariantSelectionScreen_State');

  @override
  void initState() {
    super.initState();
    _log.info('initState called');
  }

  @override
  void dispose() {
    _log.info('dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called, _isLoading: $_isLoading');

    return WillPopScope(
      onWillPop: () async {
        _log.info('WillPopScope triggered');
        Provider.of<VehicleInfoProvider>(context, listen: false).clearVehicleInfo();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Vehicle Variant'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _log.info('Back button pressed');
              Provider.of<VehicleInfoProvider>(context, listen: false).clearVehicleInfo();
              Navigator.pop(context);
            },
          ),
        ),
        body: Consumer<VehicleInfoProvider>(
          builder: (context, provider, child) {
            _log.info('Consumer builder called with:'
                '\n - variants count: ${provider.vehicleVariants.length}'
                '\n - isLoading: ${provider.isLoading}'
                '\n - has error: ${provider.error != null}'
                '\n - has vehicleInfo: ${provider.vehicleInfo != null}');

            if (_isLoading) {
              _log.info('Showing loading indicator');
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading variant details...'),
                  ],
                ),
              );
            }

            if (provider.vehicleVariants.isEmpty) {
              _log.info('No variants available');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No variants found for this vehicle',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _log.info('No variants - Go back button pressed');
                        provider.clearVehicleInfo();
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final vehicleInfo = provider.vehicleInfo;
            if (vehicleInfo == null) {
              _log.warning('Vehicle info is null with non-empty variants');
              return const Center(child: Text('Vehicle information not available'));
            }

            _log.info('Building variant list view with ${provider.vehicleVariants.length} variants');
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the specific variant of your ${vehicleInfo.year} ${vehicleInfo.make} ${vehicleInfo.model}:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.vehicleVariants.length,
                      itemBuilder: (context, index) {
                        final variant = provider.vehicleVariants[index];
                        _log.fine('Building variant tile for index $index: ${variant['VehicleDescription']}');
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              variant['VehicleDescription'] ?? 'Unknown Variant',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Body Style: ${variant['BodyStyle'] ?? 'N/A'}'),
                                Text('Trim Level: ${variant['Trim'] ?? 'N/A'}'),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              _log.info('Variant tile tapped: ${variant['VehicleId']}');
                              _handleVariantSelection(context, provider, variant);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleVariantSelection(
      BuildContext context,
      VehicleInfoProvider provider,
      Map<String, dynamic> variant
      ) async {
    if (!mounted) {
      _log.warning('Widget not mounted at start of variant selection');
      return;
    }

    // Store navigator before async operation
    final navigator = Navigator.of(context);

    try {
      setState(() {
        _isLoading = true;
        _log.info('Set _isLoading to true');
      });

      _log.info('Calling selectVariantAndFetchSafetyRatings');
      await provider.selectVariantAndFetchSafetyRatings(
        variant['VehicleId'].toString(),
      );

      _log.info('selectVariantAndFetchSafetyRatings completed. Checking mount state');
      if (!mounted) {
        _log.warning('Widget no longer mounted after safety ratings fetch');
        return;
      }

      // Check if we have the data we need
      if (provider.vehicleInfo?.safetyRatings.isNotEmpty == true) {
        _log.info('Safety ratings received, attempting navigation');

        // Use stored navigator for navigation
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const VehicleDetailsScreen(),
          ),
        );
      } else {
        _log.warning('No safety ratings received or vehicle info is null');
      }
    } catch (e) {
      _log.severe('Error in _handleVariantSelection: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _log.info('Set _isLoading to false');
        });
      } else {
        _log.warning('Widget no longer mounted in finally block');
      }
    }
  }
}