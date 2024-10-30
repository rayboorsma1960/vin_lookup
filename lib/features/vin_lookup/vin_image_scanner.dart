import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../../services/vin_validator.dart';

class VinImageScanner {
  static final _log = Logger('VinImageScanner');
  static TextRecognizer? _textRecognizer;
  static final ImagePicker _picker = ImagePicker();

  // Initialize recognizer
  static void initialize() {
    _textRecognizer?.close();
    _textRecognizer = TextRecognizer();
    _log.info('VinImageScanner initialized');
  }

  // Cleanup resources
  static void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
    _log.info('VinImageScanner disposed');
  }

  static Future<String?> scanVin() async {
    _log.info('=== Starting VIN scan process ===');

    try {
      // Ensure recognizer is initialized
      if (_textRecognizer == null) {
        initialize();
      }

      _log.info('Launching camera picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image == null) {
        _log.info('Camera picker returned null - user likely cancelled');
        return null;
      }

      // Check if recognizer is still valid after image capture
      if (_textRecognizer == null) {
        _log.warning('Text recognizer was disposed during image capture');
        initialize();
      }

      _log.info('Image captured successfully: ${image.path}');

      _log.info('Converting image to InputImage format');
      final inputImage = InputImage.fromFilePath(image.path);

      _log.info('Starting text recognition process');
      final RecognizedText recognizedText =
      await _textRecognizer!.processImage(inputImage);

      _log.info('Text recognition completed. Found ${recognizedText.blocks.length} blocks of text');
      _log.info('Full recognized text:\n${recognizedText.text}');

      String text = recognizedText.text;
      _log.info('Attempting to extract VIN from recognized text');
      String? vin = await _extractVinFromText(text);

      return vin;

    } catch (e, stackTrace) {
      _log.severe('Error during VIN scanning process: $e');
      _log.severe('Stack trace: $stackTrace');

      // Attempt recovery
      initialize();

      throw Exception('Error scanning VIN: $e');
    }
  }

  static Future<String?> _extractVinFromText(String text) async {
    _log.info('=== Starting VIN extraction process ===');
    _log.info('Input text length: ${text.length}');
    _log.info('Original text:\n$text');

    // Clean the text
    text = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ' ');
    _log.info('Cleaned text:\n$text');

    // Look for exact 17-character sequences that could be VINs
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
      }
    }

    // Try finding VIN pattern with possible corrections
    _log.info('Attempting to find VIN with corrections');
    List<String> words = text.split(RegExp(r'\s+'));

    for (String word in words) {
      if (word.length >= 15 && word.length <= 17) {
        _log.info('Checking word: $word (length: ${word.length})');
        String paddedWord = word.padRight(17, '0');
        String? suggestion = VinValidator.suggestCorrection(paddedWord);

        if (suggestion != null && VinValidator.isValid(suggestion)) {
          _log.info('Found valid VIN after correction: $suggestion');
          return suggestion;
        }
      }
    }

    _log.info('No valid VIN found in extraction process');
    return null;
  }
}