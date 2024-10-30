import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../../services/vin_validator.dart';  // Updated import path

class VinImageScanner {
  static final _log = Logger('VinImageScanner');
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> scanVin() async {
    _log.info('=== Starting VIN scan process ===');

    try {
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

      _log.info('Image captured successfully: ${image.path}');

      _log.info('Converting image to InputImage format');
      final inputImage = InputImage.fromFilePath(image.path);

      _log.info('Starting text recognition process');
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      _log.info('Text recognition completed. Found ${recognizedText.blocks.length} blocks of text');
      _log.info('Full recognized text:\n${recognizedText.text}');

      String text = recognizedText.text;
      _log.info('Attempting to extract VIN from recognized text');
      String? vin = await _extractVinFromText(text);

      return vin;  // Can be null, which is fine

    } catch (e, stackTrace) {
      _log.severe('Error during VIN scanning process: $e');
      _log.severe('Stack trace: $stackTrace');
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
      }
    }

    // Look for partial matches that might need correction
    _log.info('Searching for partial VIN patterns (15-17 characters)');
    RegExp partialPattern = RegExp(r'[A-HJ-NPR-Z0-9]{15,17}');
    matches = partialPattern.allMatches(text);

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      _log.info('Checking partial match: $potentialVin');

      String? suggestion = VinValidator.suggestCorrection(potentialVin);
      if (suggestion != null && suggestion.length == 17) {
        _log.info('Found suggested correction: $suggestion');
        return suggestion;
      }
    }

    // Check individual words
    _log.info('Checking individual words for VIN-like sequences');
    List<String> words = text.split(RegExp(r'\s+'));

    for (String word in words) {
      if (word.length >= 15 && word.length <= 17) {
        _log.info('Checking word: $word (length: ${word.length})');

        String paddedWord = word.padRight(17, '0');
        String? suggestion = VinValidator.suggestCorrection(paddedWord);
        if (suggestion != null && VinValidator.isValid(suggestion)) {
          _log.info('Found suggestion from word: $suggestion');
          return suggestion;
        }
      }
    }

    _log.info('No valid VIN found in extraction process');
    return null;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}