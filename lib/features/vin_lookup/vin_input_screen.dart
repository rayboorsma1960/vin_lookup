// vin_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../services/vehicle_info_provider.dart';
import '../../services/vin_validator.dart';
import 'vehicle_variant_selection_screen.dart';
import '../vehicle_details/vehicle_details_screen.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart' show PlatformException;

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
  String? _errorMessage;

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

                  // Error Message Display
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _errorMessage = null),
                            color: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      errorMaxLines: 2,
                      helperText: 'Example: 1HGCM82633A123456',
                      helperMaxLines: 2,
                    ),
                    enabled: !_isLoading,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                    maxLength: 17,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateVin,
                    onChanged: (value) {
                      if (value != value.toUpperCase()) {
                        _vinController.value = TextEditingValue(
                          text: value.toUpperCase(),
                          selection: _vinController.selection,
                        );
                      }
                      // Clear error message when user starts typing
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _scanVin,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scan VIN'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _scanBarcodeVin,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Barcode'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitVin,
                          icon: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.search),
                          label: Text(_isLoading ? 'Searching...' : 'Look Up'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Help Section
                  if (!_isLoading) ...[
                    const SizedBox(height: 32),
                    _buildHelpSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where to find your VIN?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              icon: Icons.credit_card,
              text: 'Driver\'s side dashboard near windshield',
            ),
            _buildHelpItem(
              icon: Icons.document_scanner,
              text: 'Vehicle registration document',
            ),
            _buildHelpItem(
              icon: Icons.car_repair,
              text: 'Driver\'s side door jamb',
            ),
            _buildHelpItem(
              icon: Icons.qr_code,
              text: 'Barcode on driver\'s side door frame',
            ),
            _buildHelpItem(
              icon: Icons.policy,
              text: 'Insurance card or policy',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateVin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a VIN';
    }
    if (value.length != 17) {
      return 'VIN must be exactly 17 characters long';
    }
    if (!VinValidator.isValid(value)) {
      return 'Please enter a valid VIN. Check for common mistakes:\n• Letter O vs number 0\n• Letter I vs number 1';
    }
    return null;
  }

  Future<void> _scanBarcodeVin() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      var scanResult = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
          restrictFormat: [BarcodeFormat.code39, BarcodeFormat.pdf417],
          useCamera: -1, // Use back camera
          autoEnableFlash: false,
        ),
      );

      _log.info('Scan result type: ${scanResult.type}');
      _log.info('Scanned barcode: ${scanResult.rawContent}');

      if (scanResult.type == ResultType.Barcode && scanResult.rawContent.isNotEmpty) {
        String scannedText = scanResult.rawContent.trim().toUpperCase();

        // Method 1: First 17 characters
        if (scannedText.length >= 17) {
          String potentialVin = scannedText.substring(0, 17);
          if (VinValidator.isValid(potentialVin)) {
            setState(() {
              _vinController.text = potentialVin;
              _errorMessage = null;
            });
            return;
          }
        }

        // Method 2: Search for VIN pattern
        RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
        Iterable<Match> matches = vinPattern.allMatches(scannedText);

        for (Match match in matches) {
          String potentialVin = match.group(0)!;
          if (VinValidator.isValid(potentialVin)) {
            setState(() {
              _vinController.text = potentialVin;
              _errorMessage = null;
            });
            return;
          }
        }

        // If we get here, no valid VIN was found
        String? suggestion = VinValidator.suggestCorrection(scannedText);
        if (suggestion != null) {
          _showCorrectionDialog(scannedText, suggestion);
        } else {
          _showErrorDialog(
            'Could not extract a valid VIN from the scanned barcode.\n\n'
                'Scanned text: $scannedText\n\n'
                'Please try scanning again or enter the VIN manually.',
          );
        }
      }
    } on PlatformException catch (e) {
      _log.severe('Platform error while scanning: $e');
      if (e.code == 'PERMISSION_NOT_GRANTED') {
        _showErrorDialog(
          'Camera permission was denied.\n\n'
              'Please grant camera permission in your device settings to use the scanner.',
        );
      } else {
        _showErrorDialog(
          'Error scanning barcode: ${e.message}\n'
              'Please try again or enter the VIN manually.',
        );
      }
    } catch (e) {
      _log.severe('Error scanning VIN barcode: $e');
      _showErrorDialog(
        'Error scanning barcode: ${e.toString()}\n'
            'Please try again or enter the VIN manually.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitVin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final provider = Provider.of<VehicleInfoProvider>(context, listen: false);
        await provider.fetchVehicleInfo(_vinController.text);

        if (!mounted) return;

        if (provider.error != null) {
          setState(() {
            _errorMessage = provider.getUserFriendlyError();
          });
        } else if (provider.vehicleInfo != null) {
          if (provider.vehicleVariants.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VehicleVariantSelectionScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VehicleDetailsScreen(),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _scanVin() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

        _log.info('Recognized text: ${recognizedText.text}');

        String text = recognizedText.text;
        String? vin = _extractVin(text);

        if (vin != null) {
          if (VinValidator.isValid(vin)) {
            setState(() {
              _vinController.text = vin;
              _errorMessage = null;
            });
          } else {
            String? suggestion = VinValidator.suggestCorrection(vin);
            if (suggestion != null) {
              _showCorrectionDialog(vin, suggestion);
            } else {
              _showErrorDialog(
                'Could not validate the detected VIN: $vin\n\n'
                    'Please try scanning again or enter the VIN manually.',
              );
            }
          }
        } else {
          _showErrorDialog(
            'No valid VIN pattern found.\n\n'
                'Recognized text:\n${recognizedText.text}\n\n'
                'Please try scanning again or enter the VIN manually.',
          );
        }
      }
    } catch (e) {
      _log.severe('Error scanning VIN: $e');
      _showErrorDialog(
        'Error scanning VIN: ${e.toString()}\n'
            'Please try again or enter the VIN manually.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractVin(String text) {
    _log.info('Extracting VIN from text: $text');

    // Clean the text
    text = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ' ');

    // Look for exact 17-character sequences that could be VINs
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    Iterable<Match> matches = vinPattern.allMatches(text);

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      _log.info('Found potential VIN: $potentialVin');

      if (VinValidator.isValid(potentialVin)) {
        _log.info('Valid VIN extracted: $potentialVin');
        return potentialVin;
      }
    }

    // Look for partial matches
    RegExp partialPattern = RegExp(r'[A-HJ-NPR-Z0-9]{15,17}');
    matches = partialPattern.allMatches(text);

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      _log.info('Found partial VIN: $potentialVin');

      if (potentialVin.length == 17) {
        String? suggestion = VinValidator.suggestCorrection(potentialVin);
        if (suggestion != null) {
          _log.info('Suggested correction for VIN: $suggestion');
          return suggestion;
        }
      }
    }

    // Check individual words for VIN-like sequences
    List<String> words = text.split(RegExp(r'\s+'));
    for (String word in words) {
      if (word.length >= 15 && word.length <= 17) {
        _log.info('Checking word for VIN-like sequence: $word');

        String paddedWord = word.padRight(17, '0');
        String? suggestion = VinValidator.suggestCorrection(paddedWord);

        if (suggestion != null) {
          _log.info('Found possible VIN from word: $suggestion');
          return suggestion;
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
            const Text('The scanned VIN might need correction:'),
            const SizedBox(height: 16),
            _buildVinComparisonRow('Original', original),
            const SizedBox(height: 8),
            _buildVinComparisonRow('Suggested', suggestion),
            const SizedBox(height: 16),
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

  Widget _buildVinComparisonRow(String label, String vin) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              vin,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
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