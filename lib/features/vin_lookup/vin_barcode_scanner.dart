import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:logging/logging.dart';

class VinBarcodeScanner {
  static final _log = Logger('VinBarcodeScanner');

  // Configuration constants
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(milliseconds: 1000);

  static Future<String?> scanBarcode() async {
    int retryCount = 0;
    bool hasTriedFlash = false;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    try {
      while (retryCount < _maxRetries) {
        // Alternate between flash off and on after first failed attempt
        bool useFlash = retryCount > 0 && !hasTriedFlash;

        final scanOptions = ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash On',
            'flash_off': 'Flash Off',
          },
          restrictFormat: [
            BarcodeFormat.code39,
            BarcodeFormat.code128,
            BarcodeFormat.pdf417,
          ],
          useCamera: -1,
          // Enable flash based on retry strategy
          autoEnableFlash: useFlash,
          android: const AndroidOptions(
            aspectTolerance: 0.25,
            useAutoFocus: true,
          ),
        );

        try {
          _log.info('Starting scan attempt ${retryCount + 1}/$_maxRetries (Flash: ${useFlash ? 'ON' : 'OFF'})');

          // Extra delay on first attempt or when changing flash state
          if (retryCount == 0 || useFlash) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }

          var scanResult = await BarcodeScanner.scan(options: scanOptions);
          _log.info('Scan result type: ${scanResult.type}');
          _log.info('Scan format: ${scanResult.format}');
          _log.info('Raw content: "${scanResult.rawContent}"');

          if (scanResult.type == ResultType.Barcode) {
            String rawContent = scanResult.rawContent.trim();

            if (rawContent.isEmpty) {
              _log.warning('Empty scan result, retrying...');
              retryCount++;
              if (useFlash) hasTriedFlash = true;
              continue;
            }

            _log.info('Processing scan result: $rawContent');
            String? vin = await _extractVinFromBarcodeData(rawContent);

            if (vin != null) {
              _log.info('Valid VIN extracted: $vin');
              return vin;
            }

            _log.warning('No valid VIN found in content, retrying...');
            if (useFlash) hasTriedFlash = true;
            retryCount++;

          } else if (scanResult.type == ResultType.Cancelled) {
            // If user manually toggles flash, don't count as retry
            if (retryCount > 0 && !useFlash) {
              _log.info('Scan cancelled by user after attempts');
              return null;
            }
            _log.info('Scan cancelled, trying again...');
            if (useFlash) hasTriedFlash = true;
            retryCount++;

          } else {
            _log.warning('Unexpected result type: ${scanResult.type}');
            if (useFlash) hasTriedFlash = true;
            retryCount++;
          }

          if (retryCount < _maxRetries) {
            _log.info('Waiting ${_retryDelay.inMilliseconds}ms before retry');
            await Future.delayed(_retryDelay);
          }

        } on PlatformException catch (e, stackTrace) {
          _log.severe('Platform exception during scan', e, stackTrace);

          if (e.code == 'PERMISSION_NOT_GRANTED') {
            _log.warning('Camera permission denied');
            return null;
          }

          if (useFlash) hasTriedFlash = true;
          retryCount++;
          if (retryCount >= _maxRetries) {
            throw Exception('Scanner error after $_maxRetries attempts: ${e.message}');
          }

          await Future.delayed(const Duration(milliseconds: 1500));

        } catch (e, stackTrace) {
          _log.severe('Unexpected error during scan', e, stackTrace);
          if (useFlash) hasTriedFlash = true;
          retryCount++;

          if (retryCount >= _maxRetries) {
            throw Exception('Unexpected error after $_maxRetries attempts: $e');
          }

          await Future.delayed(_retryDelay);
        }
      }

      _log.warning('Failed to scan after $_maxRetries attempts');
      return null;

    } finally {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  static Future<String?> _extractVinFromBarcodeData(String data) async {
    _log.info('Starting VIN extraction from data: "$data"');

    String cleanData = data
        .replaceAll(RegExp(r'[\s\n\r\t]'), '')
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .toUpperCase();

    _log.info('Cleaned data: "$cleanData"');

    // Try direct extraction first
    if (cleanData.length >= 17) {
      String potentialVin = cleanData.substring(0, 17);
      if (_isValidVinPattern(potentialVin)) {
        return potentialVin;
      }
    }

    // Try finding VIN pattern anywhere in the string
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    for (Match match in vinPattern.allMatches(cleanData)) {
      String potentialVin = match.group(0)!;
      if (_isValidVinPattern(potentialVin)) {
        return potentialVin;
      }
    }

    return null;
  }

  static bool _isValidVinPattern(String vin) {
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      _log.info('VIN failed format check: $vin');
      return false;
    }

    if (vin.contains(RegExp(r'[IOQ]'))) {
      //_Log.info('VIN contains invalid characters: $vin');
      return false;
    }

    //_Log.info('VIN passed validation: $vin');
    return true;
  }
}