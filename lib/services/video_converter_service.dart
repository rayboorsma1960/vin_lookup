import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

class VideoConverterService {
  static final VideoConverterService _instance = VideoConverterService._internal();
  static final _log = Logger('VideoConverterService');

  factory VideoConverterService() => _instance;
  VideoConverterService._internal();

  // Keep the original method name for backward compatibility
  Future<String?> downloadAndConvertVideo(String url, BuildContext context) async {
    try {
      // Use application cache directory
      final appDir = await getApplicationCacheDirectory();
      _log.info('Using cache directory: ${appDir.path}');

      // For this approach, we're just returning the URL directly
      // No need to download the file for WebView playback
      _log.info('Using WebView to play video from URL: $url');

      return url;
    } catch (e) {
      _log.severe('Error in downloadAndConvertVideo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().contains('empty')
                    ? 'Crash test video is not available for this vehicle'
                    : 'Error processing video: $e'
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  bool isWmvFormat(String url) {
    return path.extension(url).toLowerCase() == '.wmv';
  }
}