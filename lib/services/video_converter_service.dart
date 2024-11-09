import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

class VideoConverterService {
  static final VideoConverterService _instance = VideoConverterService._internal();
  static final _log = Logger('VideoConverterService');

  factory VideoConverterService() => _instance;
  VideoConverterService._internal();

  Future<String?> downloadAndConvertVideo(String url, BuildContext context) async {
    try {
      // Use application cache directory
      final appDir = await getApplicationCacheDirectory();
      _log.info('Using cache directory: ${appDir.path}');

      // Ensure directory exists
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final wmvFile = File('${appDir.path}/temp_$timestamp.wmv');
      final mp4File = File('${appDir.path}/converted_$timestamp.mp4');

      // Download the WMV file with size verification
      _log.info('Downloading video from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      // Check if the file is empty
      if (response.contentLength == null || response.contentLength == 0) {
        _log.warning('Empty video file received from URL: $url');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crash test video is not available for this vehicle'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      _log.info('Writing WMV file (${response.contentLength} bytes) to: ${wmvFile.path}');
      await wmvFile.writeAsBytes(response.bodyBytes);

      if (!await wmvFile.exists()) {
        throw Exception('Failed to write WMV file');
      }

      // Verify the downloaded file size
      final downloadedSize = await wmvFile.length();
      if (downloadedSize == 0) {
        await wmvFile.delete();
        throw Exception('Downloaded video file is empty');
      }

      // Convert WMV to MP4 using FFmpeg
      _log.info('Starting FFmpeg conversion');
      final session = await FFmpegKit.execute(
          '-i "${wmvFile.path}" -c:v mpeg4 -c:a aac "${mp4File.path}"'
      );

      final returnCode = await session.getReturnCode();
      final logs = await session.getLogs();

      // Print each log entry for debugging
      String fullLog = '';
      for (Log log in logs) {
        final message = log.getMessage();
        fullLog += '$message\n';
        _log.info('FFmpeg: $message');
      }

      // Clean up the temporary WMV file
      try {
        if (await wmvFile.exists()) {
          await wmvFile.delete();
          _log.info('Deleted temporary WMV file');
        }
      } catch (e) {
        _log.warning('Failed to delete temporary WMV file: $e');
      }

      if (ReturnCode.isSuccess(returnCode)) {
        if (await mp4File.exists()) {
          final fileSize = await mp4File.length();
          _log.info('Conversion successful. MP4 file created at: ${mp4File.path} (${fileSize} bytes)');
          return mp4File.path;
        } else {
          throw Exception('MP4 file not created despite successful return code');
        }
      } else {
        throw Exception('Video conversion failed:\n$fullLog');
      }
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