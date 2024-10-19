import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/vehicle_info_provider.dart';
import '../../services/vin_validator.dart';
import '../vehicle_details/vehicle_details_screen.dart';
import 'package:logging/logging.dart';

class VinInputScreen extends StatefulWidget {
  const VinInputScreen({Key? key}) : super(key: key);

  @override
  State<VinInputScreen> createState() => _VinInputScreenState();
}

class _VinInputScreenState extends State<VinInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vinController = TextEditingController();
  final _log = Logger('VinInputScreen');
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter VIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _vinController,
                  decoration: const InputDecoration(
                    labelText: 'VIN',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateVin,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitVin,
                  child: const Text('Submit'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _scanVin,
                  child: const Text('Scan VIN with Camera'),
                ),
              ],
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

  Future<void> _scanVin() async {
    try {
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
          _showErrorDialog('No valid VIN found in the image');
        }
      } else {
        _showErrorDialog('No image selected');
      }
    } catch (e) {
      _showErrorDialog('Error processing image: $e');
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
      builder: (context) => AlertDialog(
        title: Text('VIN Correction'),
        content: Text('The scanned VIN might be incorrect. Did you mean: $suggestion?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vinController.text = original;
              });
            },
            child: Text('Use Original'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vinController.text = suggestion;
              });
            },
            child: Text('Use Suggestion'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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