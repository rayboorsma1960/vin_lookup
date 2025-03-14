import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final bool isLocalFile;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.isLocalFile,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  final _log = Logger('VideoPlayerScreen');
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
      ..loadHtmlString(_buildHtml(widget.videoPath));
  }

  String _buildHtml(String videoUrl) {
    // Determine video type based on file extension
    final isWmv = path.extension(videoUrl).toLowerCase() == '.wmv';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            background-color: black; 
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .video-container {
            position: relative;
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          iframe {
            width: 100%;
            height: 100%;
            border: none;
          }
          .video-fallback {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: white;
            font-family: Arial, sans-serif;
          }
          .play-button {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background-color: rgba(255, 255, 255, 0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            margin-bottom: 20px;
          }
          .play-icon {
            width: 0;
            height: 0;
            border-style: solid;
            border-width: 20px 0 20px 30px;
            border-color: transparent transparent transparent white;
            margin-left: 5px;
          }
          .open-browser-btn {
            background-color: rgba(0, 123, 255, 0.7);
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 15px;
          }
        </style>
      </head>
      <body>
        <div class="video-container" id="container">
          ${isWmv ? _buildWmvIframe(videoUrl) : _buildHtmlVideo(videoUrl)}
        </div>
        
        <script>
          // Function to handle fallback if iframe fails
          function showFallback() {
            document.getElementById('container').innerHTML = `
              <div class="video-fallback">
                <div class="play-button">
                  <div class="play-icon"></div>
                </div>
                <p>This video format may not be supported in the app.</p>
                <button class="open-browser-btn" onclick="window.open('$videoUrl', '_blank')">
                  Open in browser
                </button>
              </div>
            `;
          }
          
          // Check if iframe loaded correctly (for WMV)
          window.addEventListener('load', function() {
            const iframe = document.getElementById('video-iframe');
            if (iframe) {
              iframe.onerror = showFallback;
              
              // Additional check - if after 3 seconds the video hasn't loaded,
              // show the fallback (handles some cases where onerror doesn't fire)
              setTimeout(function() {
                try {
                  const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                  if (!iframeDoc || iframeDoc.body.innerHTML === '') {
                    showFallback();
                  }
                } catch(e) {
                  // If we can't access iframe content due to CORS, assume it's working
                }
              }, 3000);
            }
          });
          
          // Handle video errors (for HTML5 video)
          const video = document.getElementById('videoPlayer');
          if (video) {
            video.addEventListener('error', function(e) {
              console.error('Video error:', e);
              showFallback();
            });
          }
        </script>
      </body>
      </html>
    ''';
  }

  String _buildWmvIframe(String videoUrl) {
    // For WMV, use an iframe to let the browser handle it natively
    return '''
      <iframe 
        id="video-iframe"
        src="$videoUrl" 
        allowfullscreen
        allow="autoplay; fullscreen">
      </iframe>
    ''';
  }

  String _buildHtmlVideo(String videoUrl) {
    // For other formats, use HTML5 video element
    return '''
      <video id="videoPlayer" controls autoplay>
        <source src="$videoUrl" type="video/mp4">
        Your browser does not support HTML5 video.
      </video>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Test Video'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}