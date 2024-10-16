import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class GoogleImageService {
  final _log = Logger('GoogleImageService');
  final String _apiKey = 'AIzaSyADGYeGRS9_Q7UN3Sh_czLqQX9uRtaX4w0';
  final String _cx = '97650f7fceeb54477';

  Future<String> getVehicleImage(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = 'https://www.googleapis.com/customsearch/v1?q=$encodedQuery&key=$_apiKey&cx=$_cx&searchType=image&num=1';

    _log.info('Fetching image for query: $query');
    _log.info('Full URL with all parameters: $url');

    try {
      final response = await http.get(Uri.parse(url));

      _log.info('Response status code: ${response.statusCode}');
      _log.info('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        final items = jsonResult['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final imageUrl = items[0]['link'] as String;
          _log.info('Found image URL: $imageUrl');
          return imageUrl;
        } else {
          _log.warning('No image items found in the response');
        }
      } else {
        _log.warning('Error: Non-200 status code. Body: ${response.body}');
      }
    } catch (e) {
      _log.severe('Error fetching image: $e');
    }

    _log.info('Returning fallback image URL');
    return 'https://via.placeholder.com/300x200?text=No+Image+Available';
  }
}