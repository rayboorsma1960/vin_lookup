// vehicle_variant_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/vehicle_info_provider.dart';
import '../vehicle_details/vehicle_details_screen.dart';
import 'package:logging/logging.dart';

class VehicleVariantSelectionScreen extends StatefulWidget {
  const VehicleVariantSelectionScreen({super.key});

  @override
  State<VehicleVariantSelectionScreen> createState() => _VehicleVariantSelectionScreenState();
}

class _VehicleVariantSelectionScreenState extends State<VehicleVariantSelectionScreen> {
  static final _log = Logger('VehicleVariantSelectionScreen');
  bool _isLoading = false;
  String? _errorMessage;
  late VehicleInfoProvider _provider;

  @override
  void initState() {
    super.initState();
    _log.info('initState called');
    _provider = Provider.of<VehicleInfoProvider>(context, listen: false);

    // Add automatic variant selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectVariant();
    });
  }

  // New method to handle automatic variant selection
  Future<void> _autoSelectVariant() async {
    if (_provider.vehicleVariants.length == 1) {
      _log.info('Single variant found - auto-selecting');

      setState(() {
        _isLoading = true;
      });

      try {
        await _provider.selectVariantAndFetchSafetyRatings(
          _provider.vehicleVariants[0]['VehicleId'].toString(),
        );

        if (!mounted) return;

        if (_provider.error != null) {
          setState(() {
            _errorMessage = _provider.getUserFriendlyError();
          });
        } else if (_provider.vehicleInfo?.safetyRatings.isNotEmpty == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleDetailsScreen(),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Safety ratings are not available for this variant.';
          });
        }
      } catch (e) {
        _log.severe('Error in autoSelectVariant: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load variant details. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _log.info('WillPopScope triggered');
        _provider.clearVehicleInfo();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Vehicle Variant'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _log.info('Back button pressed');
              _provider.clearVehicleInfo();
              Navigator.pop(context);
            },
          ),
        ),
        body: Consumer<VehicleInfoProvider>(
          builder: (context, provider, child) {
            if (_isLoading || provider.isLoading) {
              return _buildLoadingState();
            }

            if (provider.error != null) {
              return _buildErrorState(provider.getUserFriendlyError());
            }

            if (provider.vehicleVariants.isEmpty) {
              return _buildEmptyState(provider);
            }

            final vehicleInfo = provider.vehicleInfo;
            if (vehicleInfo == null) {
              return _buildErrorState('Vehicle information is unavailable. Please try again.');
            }

            return _buildContent(context, provider, vehicleInfo);
          },
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
            'Loading variant details...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
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

  Widget _buildEmptyState(VehicleInfoProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'No variants found for your ${provider.vehicleInfo?.year} ${provider.vehicleInfo?.make} ${provider.vehicleInfo?.model}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This could mean the vehicle has a single standard configuration.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearVehicleInfo();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
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

  Widget _buildContent(BuildContext context, VehicleInfoProvider provider, dynamic vehicleInfo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicleInfo.year} ${vehicleInfo.make} ${vehicleInfo.model}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your specific vehicle variant to view detailed information and safety ratings:',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: provider.vehicleVariants.length,
              itemBuilder: (context, index) {
                final variant = provider.vehicleVariants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      variant['VehicleDescription'] ?? 'Unknown Variant',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        if (variant['BodyStyle']?.isNotEmpty == true)
                          _buildVariantDetail('Body Style', variant['BodyStyle'], Icons.car_crash),
                        if (variant['Trim']?.isNotEmpty == true)
                          _buildVariantDetail('Trim Level', variant['Trim'], Icons.style),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _handleVariantSelection(variant),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantDetail(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVariantSelection(Map<String, dynamic> variant) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _log.info('Selecting variant: ${variant['VehicleId']}');

      await _provider.selectVariantAndFetchSafetyRatings(
        variant['VehicleId'].toString(),
      );

      if (!mounted) return;

      if (_provider.error != null) {
        setState(() {
          _errorMessage = _provider.getUserFriendlyError();
        });
      } else if (_provider.vehicleInfo?.safetyRatings.isNotEmpty == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VehicleDetailsScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Safety ratings are not available for this variant.';
        });
      }
    } catch (e) {
      _log.severe('Error in handleVariantSelection: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load variant details. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}