import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logging/logging.dart';

class WebViewVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const WebViewVideoPlayer({super.key, required this.videoUrl});

  @override
  State<WebViewVideoPlayer> createState() => _WebViewVideoPlayerState();
}

class _WebViewVideoPlayerState extends State<WebViewVideoPlayer> {
  late final WebViewController _controller;
  final _log = Logger('WebViewVideoPlayer');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _log.severe('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_buildHtml(widget.videoUrl));
  }

  String _buildHtml(String videoUrl) {
    // Create a simple HTML page with a video player
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 0; background-color: black; }
          .video-container {
            position: relative;
            width: 100%;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          video {
            max-width: 100%;
            max-height: 100%;
          }
          .play-button {
            position: absolute;
            background-color: rgba(0,0,0,0.5);
            border: none;
            color: white;
            border-radius: 50%;
            width: 80px;
            height: 80px;
            font-size: 24px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .play-button:before {
            content: "▶";
          }
          .error-message {
            color: white;
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 20px;
          }
        </style>
      </head>
      <body>
        <div class="video-container">
          <video id="videoPlayer" controls>
            <source src="$videoUrl" type="video/x-ms-wmv">
            <div class="error-message">
              Your browser does not support WMV video playback.
              <br><br>
              <button onclick="window.open('$videoUrl', '_blank')">
                Open video in browser
              </button>
            </div>
          </video>
        </div>
        
        <script>
          // Handle video errors
          document.getElementById('videoPlayer').addEventListener('error', function(e) {
            console.error('Video error:', e);
            
            // Create error message
            var container = document.querySelector('.video-container');
            container.innerHTML = '<div class="error-message">' +
              'Unable to play this video format.' +
              '<br><br>' +
              '<button onclick="window.open(\\'$videoUrl\\', \\'_blank\\')">Open video in browser</button>' +
              '</div>';
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}