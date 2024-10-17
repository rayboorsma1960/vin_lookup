import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/vehicle_info_provider.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
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
    );
  }

  String? _validateVin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a VIN';
    }
    if (value.length != 17) {
      return 'VIN must be 17 characters long';
    }
    if (value.contains('I') || value.contains('O') || value.contains('Q')) {
      return 'VIN cannot contain I, O, or Q';
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
        _extractVin(text);
      } else {
        _showErrorDialog('No image selected');
      }
    } catch (e) {
      _showErrorDialog('Error processing image: $e');
    }
  }

  void _extractVin(String text) {
    RegExp vinPattern = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
    Iterable<Match> matches = vinPattern.allMatches(text);

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      if (_validateVin(potentialVin) == null) {
        setState(() {
          _vinController.text = potentialVin;
        });
        return;
      }
    }

    _showErrorDialog('No valid VIN found in the image');
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