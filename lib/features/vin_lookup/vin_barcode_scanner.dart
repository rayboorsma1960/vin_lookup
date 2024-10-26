import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:logging/logging.dart';

class VinBarcodeScanner {
  static final _log = Logger('VinBarcodeScanner');

  static Future<String?> scanBarcode() async {
    try {
      _log.info('Starting barcode scan');

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
        return _extractVinFromBarcodeData(scanResult.rawContent);
      }
      return null;

    } on PlatformException catch (e) {
      _log.severe('Platform error while scanning: $e');
      if (e.code == 'PERMISSION_NOT_GRANTED') {
        throw Exception('Camera permission was denied');
      } else {
        throw Exception('Unknown error: $e');
      }
    } on FormatException {
      _log.info('User canceled the scan');
      return null;
    } catch (e) {
      _log.severe('Error scanning: $e');
      throw Exception('Error scanning barcode: $e');
    }
  }

  static String? _extractVinFromBarcodeData(String data) {
    _log.info('Attempting to extract VIN from barcode data');
    String cleanData = data.trim().toUpperCase();
    _log.info('Cleaned barcode data: $cleanData');

    // Method 1: First 17 characters (most common for PDF417)
    if (cleanData.length >= 17) {
      String potentialVin = cleanData.substring(0, 17);
      if (_isValidVinPattern(potentialVin)) {
        _log.info('Found VIN at start of data: $potentialVin');
        return potentialVin;
      }
    }

    // Method 2: Search for VIN pattern
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    Iterable<Match> matches = vinPattern.allMatches(cleanData);

    for (Match match in matches) {
      String potentialVin = match.group(0)!;
      if (_isValidVinPattern(potentialVin)) {
        _log.info('Found VIN pattern in data: $potentialVin');
        return potentialVin;
      }
    }

    _log.warning('No valid VIN found in barcode data');
    throw Exception('No valid VIN found in barcode data');
  }

  static bool _isValidVinPattern(String vin) {
    // Basic VIN pattern validation
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      return false;
    }

    // Check for invalid characters
    if (vin.contains(RegExp(r'[IOQ]'))) {
      return false;
    }

    return true;
  }
}