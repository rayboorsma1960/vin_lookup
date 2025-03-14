import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// Import the navigator key from main.dart
import '../../main.dart' show navigatorKey;

class VinBarcodeScanner {
  static final _log = Logger('VinBarcodeScanner');
  static bool _scanInProgress = false;

  /// Scans a barcode and attempts to extract a VIN
  static Future<String?> scanBarcode() async {
    // Prevent multiple concurrent scans
    if (_scanInProgress) {
      _log.warning('Scan already in progress, ignoring this request');
      return null;
    }

    _scanInProgress = true;

    try {
      // Force portrait orientation for consistent scanning
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Create a completer to handle the async result
      Completer<String?> completer = Completer<String?>();

      // Use the navigator key from main.dart
      if (navigatorKey.currentContext != null) {
        // Navigate to scanner page
        await Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => BarcodeScannerPage(
              onScanComplete: (String? result) {
                if (!completer.isCompleted) {
                  completer.complete(result);
                }
              },
            ),
          ),
        );

        // Wait for scan result
        return await completer.future;
      } else {
        _log.severe('No valid context available for showing scanner');
        return null;
      }

    } catch (e) {
      _log.severe('Error during barcode scanning', e);
      return null;
    } finally {
      // Reset orientation and scan flag
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _scanInProgress = false;
    }
  }

  static Future<String?> _extractVinFromBarcodeData(String data) async {
    _log.info('Starting VIN extraction from data: "$data"');

    // Pre-process: First try with minimal cleaning
    String minimallyCleaned = data
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .trim();

    _log.info('Minimally cleaned data: "$minimallyCleaned"');

    // Try to find a VIN in minimally cleaned data
    String? vin = _findVinInString(minimallyCleaned);
    if (vin != null) return vin;

    // More aggressive cleaning
    String aggressivelyCleaned = data
        .replaceAll(RegExp(r'[\s\n\r\t]'), '')
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .toUpperCase();

    _log.info('Aggressively cleaned data: "$aggressivelyCleaned"');

    // Try to find VIN in aggressively cleaned data
    return _findVinInString(aggressivelyCleaned);
  }

  static String? _findVinInString(String input) {
    // If input itself is a valid VIN pattern
    if (input.length == 17 && _isValidVinPattern(input)) {
      return input;
    }

    // Try to extract the first 17 chars
    if (input.length >= 17) {
      String potentialVin = input.substring(0, 17);
      if (_isValidVinPattern(potentialVin)) {
        return potentialVin;
      }
    }

    // Try finding VIN pattern anywhere in the string
    RegExp vinPattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    for (Match match in vinPattern.allMatches(input)) {
      String potentialVin = match.group(0)!;
      if (_isValidVinPattern(potentialVin)) {
        return potentialVin;
      }
    }

    // Try more lenient regex with looser requirements
    RegExp lenientPattern = RegExp(r'[A-Z0-9]{17}');
    for (Match match in lenientPattern.allMatches(input)) {
      String potentialVin = match.group(0)!;
      _log.info('Found potential VIN with lenient pattern: $potentialVin');
      // Report it even if it contains I,O,Q (might be a misread)
      return potentialVin;
    }

    return null;
  }

  static bool _isValidVinPattern(String vin) {
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      _log.info('VIN failed format check: $vin');
      return false;
    }

    if (vin.contains(RegExp(r'[IOQ]'))) {
      _log.info('VIN contains invalid characters (I, O, or Q): $vin');
      return false;
    }

    _log.info('VIN passed validation: $vin');
    return true;
  }
}

// Scanner UI page
class BarcodeScannerPage extends StatefulWidget {
  final Function(String?) onScanComplete;

  const BarcodeScannerPage({super.key, required this.onScanComplete});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _flashOn = false;
  bool _processingBarcode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan VIN Barcode'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                _flashOn = !_flashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onBarcodeDetected,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
              child: CustomPaint(
                painter: ScannerOverlayPainter(),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'Position the barcode within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onScanComplete(null);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processingBarcode) return; // Prevent duplicate processing
    _processingBarcode = true;

    try {
      final List<Barcode> barcodes = capture.barcodes;

      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        if (barcode.rawValue != null) {
          final rawValue = barcode.rawValue!;

          // Process the scanned value to extract VIN
          final vinResult = await VinBarcodeScanner._extractVinFromBarcodeData(rawValue);

          // Return either the VIN or the raw value if no VIN pattern found
          final result = vinResult ?? (rawValue.length >= 10 ? rawValue : null);

          if (result != null) {
            // Stop the scanner
            await controller.stop();

            // Return the result and close the scanner page
            widget.onScanComplete(result);
            if (mounted) {
              Navigator.pop(context);
            }
          }
        }
      }
    } finally {
      // Reset the processing flag to allow another scan attempt if needed
      _processingBarcode = false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanAreaPath = Path()
      ..addRect(Rect.fromLTRB(left, top, right, bottom));

    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(128)  // Using withAlpha instead of withOpacity
      ..style = PaintingStyle.fill;

    final scanAreaPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    // Create a hole in the background
    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );

    canvas.drawPath(path, backgroundPaint);
    canvas.drawPath(scanAreaPath, scanAreaPaint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = scanAreaSize * 0.1;

    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}