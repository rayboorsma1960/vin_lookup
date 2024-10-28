// vin_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../services/vehicle_info_provider.dart';
import '../../services/vin_validator.dart';
import 'vehicle_variant_selection_screen.dart';
import '../../features/feedback/feedback_screen.dart';
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
        title: const Text('VIN Lookup'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
            icon: const Icon(Icons.feedback, color: Colors.red),
            label: const Text(
              'Feedback',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,  // Optional: makes the text bolder
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),  // Optional: adds a light red background
            ),
          ),
        ],
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
                  // Action Buttons
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(  // Changed from ElevatedButton.icon
                          onPressed: _isLoading ? null : _scanVin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),  // Slightly reduced padding
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            side: BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Column(  // Using Column instead of icon+label
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(height: 4),  // Space between icon and text
                              Text('Scan\nVIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(  // Changed from ElevatedButton.icon
                          onPressed: _isLoading ? null : _scanBarcodeVin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),  // Slightly reduced padding
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            side: BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Column(  // Using Column instead of icon+label
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner),
                              SizedBox(height: 4),  // Space between icon and text
                              Text('Scan\nBarcode',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(  // Keep this one as ElevatedButton.icon
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
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
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
              _formKey.currentState?.validate();  // Add this line
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
          String errorMessage;

          if (provider.error!.message.contains('503')) {
            errorMessage = 'The NHTSA vehicle information service is temporarily unavailable.\n\n'
                'This is a known issue with the government database service, not with your device '
                'or internet connection.\n\n'
                'Please try again in a few minutes.';
          } else if (provider.error!.message.contains('timeout')) {
            errorMessage = 'The request timed out. Please check your internet connection and try again.';
          } else {
            errorMessage = provider.getUserFriendlyError();
          }

          setState(() {
            _errorMessage = errorMessage;
          });

          // Show a snackbar for service outage
          if (provider.error!.message.contains('503') && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service temporarily down. Please try again later.'),
                duration: Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (provider.vehicleInfo != null) {
          // Clear any existing error messages
          setState(() {
            _errorMessage = null;
          });

          if (!mounted) return;

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
      } catch (e) {
        _log.severe('Unexpected error in _submitVin: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'An unexpected error occurred. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // In the _scanVin method of VinInputScreen:

  Future<void> _scanVin() async {
    _log.info('=== Starting VIN scan process ===');

    try {
      _log.info('Setting initial state (isLoading: true, errorMessage: null)');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _log.info('Launching camera picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image == null) {
        _log.info('Camera picker returned null - user likely cancelled');
        return;
      }

      _log.info('Image captured successfully: ${image.path}');

      if (!mounted) {
        _log.warning('Widget not mounted after image capture');
        return;
      }

      _log.info('Converting image to InputImage format');
      final inputImage = InputImage.fromFilePath(image.path);

      _log.info('Starting text recognition process');
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      _log.info('Text recognition completed. Found ${recognizedText.blocks.length} blocks of text');
      _log.info('Full recognized text:\n${recognizedText.text}');

      if (!mounted) {
        _log.warning('Widget not mounted after text recognition');
        return;
      }

      String text = recognizedText.text;
      _log.info('Attempting to extract VIN from recognized text');
      String? vin = _extractVin(text);

      if (!mounted) {
        _log.warning('Widget not mounted after VIN extraction');
        return;
      }

      if (vin != null) {
        _log.info('Potential VIN found: $vin');
        if (VinValidator.isValid(vin)) {
          _log.info('VIN validated successfully');
          setState(() {
            _vinController.text = vin;
            _errorMessage = null;
            _log.info('Updated VIN controller text and cleared error message');
            _formKey.currentState?.validate();
          });
        } else {
          _log.info('Invalid VIN found, checking for possible corrections');
          String? suggestion = VinValidator.suggestCorrection(vin);
          if (suggestion != null) {
            _log.info('Correction suggested: $suggestion');
            _showCorrectionDialog(vin, suggestion);
          } else {
            _log.info('No correction available for invalid VIN');
            _showErrorDialog(
              'Could not validate the detected VIN: $vin\n\n'
                  'Please try scanning again or enter the VIN manually.',
            );
          }
        }
      } else {
        _log.info('No VIN pattern found in recognized text');
        _showErrorDialog(
          'No valid VIN pattern found.\n\n'
              'Recognized text:\n${recognizedText.text}\n\n'
              'Please try scanning again or enter the VIN manually.',
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Error during VIN scanning process: $e');
      _log.severe('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorDialog(
          'Error scanning VIN: ${e.toString()}\n'
              'Please try again or enter the VIN manually.',
        );
      }
    } finally {
      if (mounted) {
        _log.info('Resetting loading state');
        setState(() => _isLoading = false);
      } else {
        _log.warning('Widget not mounted in finally block');
      }
      _log.info('=== VIN scan process completed ===');
    }
  }

// In the _extractVin method:
  String? _extractVin(String text) {
    _log.info('=== Starting VIN extraction process ===');
    _log.info('Input text length: ${text.length}');
    _log.info('Original text:\n$text');

    // Clean the text
    text = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ' ');
    _log.info('Cleaned text:\n$text');

    // Look for exact 17-character sequences that could be VINs
    _log.info('Searching for exact 17-character VIN pattern');
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    Iterable<Match> matches = vinPattern.allMatches(text);

    int matchCount = matches.length;
    _log.info('Found $matchCount potential exact matches');

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      _log.info('Checking potential VIN: $potentialVin');

      if (VinValidator.isValid(potentialVin)) {
        _log.info('Found valid VIN: $potentialVin');
        return potentialVin;
      } else {
        _log.info('Invalid VIN pattern: $potentialVin');
      }
    }

    // Look for partial matches
    _log.info('Searching for partial VIN patterns (15-17 characters)');
    RegExp partialPattern = RegExp(r'[A-HJ-NPR-Z0-9]{15,17}');
    matches = partialPattern.allMatches(text);

    int partialMatchCount = matches.length;
    _log.info('Found $partialMatchCount potential partial matches');

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      _log.info('Checking partial match: $potentialVin');

      if (potentialVin.length == 17) {
        String? suggestion = VinValidator.suggestCorrection(potentialVin);
        if (suggestion != null) {
          _log.info('Found suggested correction: $suggestion');
          return suggestion;
        }
      }
    }

    // Check individual words
    _log.info('Checking individual words for VIN-like sequences');
    List<String> words = text.split(RegExp(r'\s+'));
    _log.info('Found ${words.length} words to check');

    for (String word in words) {
      if (word.length >= 15 && word.length <= 17) {
        _log.info('Checking word: $word (length: ${word.length})');

        String paddedWord = word.padRight(17, '0');
        String? suggestion = VinValidator.suggestCorrection(paddedWord);

        if (suggestion != null) {
          _log.info('Found suggestion from word: $suggestion');
          return suggestion;
        }
      }
    }

    _log.info('No valid VIN found in extraction process');
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