import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../../services/vin_validator.dart';

class VinImageScanner {
  static final _log = Logger('VinImageScanner');
  static TextRecognizer? _textRecognizer;
  static final ImagePicker _picker = ImagePicker();
  static bool _isScanning = false;

  // Initialize recognizer
  static void initialize() {
    print("DEBUG: VinImageScanner - Starting initialization");
    _textRecognizer?.close();
    _textRecognizer = TextRecognizer();
    print("DEBUG: VinImageScanner - Initialization complete");
    _log.info('VinImageScanner initialized');
  }

  // Cleanup resources
  static void dispose() {
    print("DEBUG: VinImageScanner - Disposing resources");
    _textRecognizer?.close();
    _textRecognizer = null;
    print("DEBUG: VinImageScanner - Resources disposed");
    _log.info('VinImageScanner disposed');
  }

  static Future<String?> scanVin() async {
    print("DEBUG: VinImageScanner - scanVin called");

    // Prevent multiple simultaneous scans
    if (_isScanning) {
      print("DEBUG: VinImageScanner - Scan already in progress, ignoring request");
      _log.warning('Scan already in progress, ignoring this request');
      return null;
    }

    _isScanning = true;
    print("DEBUG: VinImageScanner - Setting _isScanning = true");
    _log.info('=== Starting VIN scan process ===');

    try {
      // Ensure recognizer is initialized
      if (_textRecognizer == null) {
        print("DEBUG: VinImageScanner - TextRecognizer is null, initializing");
        initialize();
      }

      print("DEBUG: VinImageScanner - About to launch camera picker");
      _log.info('Launching camera picker...');

      print("DEBUG: VinImageScanner - Calling _picker.pickImage()");
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      print("DEBUG: VinImageScanner - _picker.pickImage() returned ${image != null ? 'an image' : 'null'}");

      if (image == null) {
        print("DEBUG: VinImageScanner - Image is null, user likely cancelled");
        _log.info('Camera picker returned null - user likely cancelled');
        _isScanning = false;
        return null;
      }

      // Check if recognizer is still valid after image capture
      if (_textRecognizer == null) {
        print("DEBUG: VinImageScanner - TextRecognizer became null during image capture, reinitializing");
        _log.warning('Text recognizer was disposed during image capture');
        initialize();
      }

      print("DEBUG: VinImageScanner - Image captured successfully at path: ${image.path}");
      _log.info('Image captured successfully: ${image.path}');

      print("DEBUG: VinImageScanner - Converting to InputImage format");
      _log.info('Converting image to InputImage format');
      final inputImage = InputImage.fromFilePath(image.path);

      print("DEBUG: VinImageScanner - Starting text recognition with timeout");
      _log.info('Starting text recognition process');

      // Add timeout to prevent hanging
      print("DEBUG: VinImageScanner - Setting up recognition with 15-second timeout");
      RecognizedText? recognizedText;
      try {
        recognizedText = await Future.any([
          _textRecognizer!.processImage(inputImage).then((result) {
            print("DEBUG: VinImageScanner - Text recognition completed successfully");
            return result;
          }),
          Future.delayed(const Duration(seconds: 15)).then((_) {
            print("DEBUG: VinImageScanner - TEXT RECOGNITION TIMED OUT after 15 seconds");
            throw TimeoutException('Text recognition timed out after 15 seconds');
          })
        ]);
      } catch (e) {
        print("DEBUG: VinImageScanner - Error during recognition timeout race: $e");
        rethrow;
      }

      if (recognizedText == null) {
        print("DEBUG: VinImageScanner - Recognition returned null (shouldn't happen)");
        _log.warning('Recognition returned null result');
        _isScanning = false;
        return null;
      }

      print("DEBUG: VinImageScanner - Text recognition completed with ${recognizedText.blocks.length} blocks");
      _log.info('Text recognition completed. Found ${recognizedText.blocks.length} blocks of text');

      // Print first 100 chars of text for debugging
      final previewText = recognizedText.text.length > 100
          ? recognizedText.text.substring(0, 100) + "..."
          : recognizedText.text;
      print("DEBUG: VinImageScanner - Preview of recognized text: $previewText");
      _log.info('Full recognized text:\n${recognizedText.text}');

      String text = recognizedText.text;
      print("DEBUG: VinImageScanner - Starting VIN extraction");
      _log.info('Attempting to extract VIN from recognized text');

      String? vin = await _extractVinFromText(text);
      print("DEBUG: VinImageScanner - VIN extraction returned: $vin");

      return vin;

    } on TimeoutException catch (e) {
      print("DEBUG: VinImageScanner - TIMEOUT EXCEPTION: $e");
      _log.severe('Timeout during text recognition: $e');
      return null;
    } catch (e, stackTrace) {
      print("DEBUG: VinImageScanner - EXCEPTION DURING SCANNING: $e");
      print("DEBUG: VinImageScanner - Stack trace: $stackTrace");
      _log.severe('Error during VIN scanning process: $e');
      _log.severe('Stack trace: $stackTrace');

      // Attempt recovery
      print("DEBUG: VinImageScanner - Attempting recovery by reinitializing");
      initialize();
      return null;
    } finally {
      print("DEBUG: VinImageScanner - In finally block, setting _isScanning = false");
      _isScanning = false;
    }
  }

  static Future<String?> _extractVinFromText(String text) async {
    print("DEBUG: VinImageScanner - Starting VIN extraction process");
    _log.info('=== Starting VIN extraction process ===');
    print("DEBUG: VinImageScanner - Input text length: ${text.length}");
    _log.info('Input text length: ${text.length}');

    // Clean the text
    print("DEBUG: VinImageScanner - Cleaning text");
    text = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ' ');

    // Print first 100 chars of cleaned text for debugging
    final previewCleanedText = text.length > 100
        ? text.substring(0, 100) + "..."
        : text;
    print("DEBUG: VinImageScanner - Cleaned text preview: $previewCleanedText");
    _log.info('Cleaned text:\n$text');

    // Look for exact 17-character sequences that could be VINs
    print("DEBUG: VinImageScanner - Searching for VIN pattern matches");
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    Iterable<Match> matches = vinPattern.allMatches(text);

    int matchCount = matches.length;
    print("DEBUG: VinImageScanner - Found $matchCount potential exact matches");
    _log.info('Found $matchCount potential exact matches');

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      print("DEBUG: VinImageScanner - Checking potential VIN: $potentialVin");
      _log.info('Checking potential VIN: $potentialVin');

      if (VinValidator.isValid(potentialVin)) {
        print("DEBUG: VinImageScanner - Found valid VIN: $potentialVin");
        _log.info('Found valid VIN: $potentialVin');
        return potentialVin;
      } else {
        print("DEBUG: VinImageScanner - VIN validation failed for: $potentialVin");
      }
    }

    // Try finding VIN pattern with possible corrections
    print("DEBUG: VinImageScanner - No exact matches, trying corrections");
    _log.info('Attempting to find VIN with corrections');
    List<String> words = text.split(RegExp(r'\s+'));
    print("DEBUG: VinImageScanner - Found ${words.length} words to check");

    int wordIndex = 0;
    for (String word in words) {
      if (word.length >= 15 && word.length <= 17) {
        print("DEBUG: VinImageScanner - Checking word[$wordIndex]: $word (length: ${word.length})");
        _log.info('Checking word: $word (length: ${word.length})');

        String paddedWord = word.padRight(17, '0');
        print("DEBUG: VinImageScanner - Padded word: $paddedWord");

        print("DEBUG: VinImageScanner - Calling VinValidator.suggestCorrection");
        String? suggestion = VinValidator.suggestCorrection(paddedWord);
        print("DEBUG: VinImageScanner - Suggestion returned: $suggestion");

        if (suggestion != null && VinValidator.isValid(suggestion)) {
          print("DEBUG: VinImageScanner - Found valid VIN after correction: $suggestion");
          _log.info('Found valid VIN after correction: $suggestion');
          return suggestion;
        } else if (suggestion != null) {
          print("DEBUG: VinImageScanner - Suggestion validation failed: $suggestion");
        }
      }
      wordIndex++;
    }

    print("DEBUG: VinImageScanner - No valid VIN found in extraction process");
    _log.info('No valid VIN found in extraction process');
    return null;
  }
}