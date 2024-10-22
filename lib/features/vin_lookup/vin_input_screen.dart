import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/vehicle_info_provider.dart';
import '../../services/vin_validator.dart';
import 'vehicle_variant_selection_screen.dart';
import 'package:logging/logging.dart';
import '../vehicle_details/vehicle_details_screen.dart';  // Add this import

class VinInputScreen extends StatefulWidget {
  const VinInputScreen({super.key});

  @override
  State<VinInputScreen> createState() => _VinInputScreenState();
}

class _VinInputScreenState extends State<VinInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vinController = TextEditingController();
  static final _log = Logger('VinInputScreen');
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Lookup'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  const Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Vehicle Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter your Vehicle Identification Number (VIN) or scan it using your camera',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // VIN Input Field
                  TextFormField(
                    controller: _vinController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Identification Number (VIN)',
                      hintText: 'Enter 17-character VIN',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                    maxLength: 17,
                    buildCounter: (
                        BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) {
                      return Container(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            color: currentLength == maxLength ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateVin,
                    onChanged: (value) {
                      if (value != value.toUpperCase()) {
                        _vinController.value = TextEditingValue(
                          text: value.toUpperCase(),
                          selection: _vinController.selection,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Scan Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _scanVin,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan VIN with Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitVin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Look Up Vehicle',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  // Help Text
                  if (!_isLoading) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Where to find your VIN?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The VIN can be found on your vehicle registration, insurance card, or on the driver\'s side dashboard near the windshield.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateVin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a VIN';
    }
    if (!VinValidator.isValid(value)) {
      return 'Please enter a valid 17-character VIN';
    }
    return null;
  }

  Future<void> _submitVin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        _log.info('Submitting VIN: ${_vinController.text}');
        final provider = Provider.of<VehicleInfoProvider>(context, listen: false);
        await provider.fetchVehicleInfo(_vinController.text);

        if (mounted) {
          if (provider.error != null) {
            _showErrorDialog(provider.error!);
          } else {
            // Check if we have basic vehicle info, regardless of variants
            if (provider.vehicleInfo != null) {
              if (provider.vehicleVariants.isNotEmpty) {
                // If we have variants, go to variant selection
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VehicleVariantSelectionScreen(),
                  ),
                );
              } else {
                // If no variants but we have vehicle info, go directly to details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VehicleDetailsScreen(),
                  ),
                );

                // Optionally show an informative snackbar about safety ratings
                if (provider.vehicleInfo!.year >= 1990) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Safety ratings are not available for this vehicle'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            } else {
              _showErrorDialog('Unable to retrieve vehicle information. Please try again.');
            }
          }
        }
      } catch (e) {
        _showErrorDialog('Failed to fetch vehicle information. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _scanVin() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

        String text = recognizedText.text;
        String? vin = _extractVin(text);

        if (vin != null) {
          if (VinValidator.isValid(vin)) {
            setState(() {
              _vinController.text = vin;
            });
          } else {
            String? suggestion = VinValidator.suggestCorrection(vin);
            if (suggestion != null) {
              _showCorrectionDialog(vin, suggestion);
            } else {
              _showErrorDialog('Invalid VIN detected: $vin');
            }
          }
        } else {
          _showErrorDialog(
            'No valid VIN found in the image. Please ensure the VIN is clearly visible and try again.',
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error scanning VIN: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _extractVin(String text) {
    _log.info('Extracting VIN from text: $text');
    RegExp wmiPattern = RegExp(r'\b[A-HJ-NPR-Z0-9]{4}');
    Iterable<Match> wmiMatches = wmiPattern.allMatches(text);

    for (Match match in wmiMatches) {
      int startIndex = match.start;
      if (startIndex + 17 <= text.length) {
        String potentialVin = text.substring(startIndex, startIndex + 17);
        _log.info('Potential VIN found: $potentialVin');
        if (VinValidator.isValid(potentialVin)) {
          _log.info('Valid VIN extracted: $potentialVin');
          return potentialVin;
        } else {
          String? suggestion = VinValidator.suggestCorrection(potentialVin);
          if (suggestion != null) {
            _log.info('Suggested correction for VIN: $suggestion');
            return suggestion;
          }
        }
      }
    }

    _log.warning('No valid VIN found in the text');
    return null;
  }

  void _showCorrectionDialog(String original, String suggestion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('VIN Correction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The scanned VIN might be incorrect.'),
            const SizedBox(height: 8),
            Text('Original: $original', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Suggested: $suggestion', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Which would you like to use?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vinController.text = original;
              });
            },
            child: const Text('Use Original'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vinController.text = suggestion;
              });
            },
            child: const Text('Use Suggestion'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vinController.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}