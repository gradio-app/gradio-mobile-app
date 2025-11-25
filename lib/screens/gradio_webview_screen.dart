import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/huggingface_space.dart';
import '../services/gradio_download_interceptor.dart';
import '../services/file_storage_service.dart';
import '../services/saved_files_database.dart';
import 'file_viewer_screen.dart';

class GradioWebViewScreen extends StatefulWidget {
  final HuggingFaceSpace space;

  const GradioWebViewScreen({super.key, required this.space});

  @override
  State<GradioWebViewScreen> createState() => _GradioWebViewScreenState();
}

class _GradioWebViewScreenState extends State<GradioWebViewScreen> {
  InAppWebViewController? controller;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  int pendingDownloadsCount = 0;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
  );

  @override
  void initState() {
    super.initState();
  }

  Future<void> _injectDownloadInterceptorScript() async {
    try {
      final script = GradioDownloadInterceptor.generateInterceptorScript(widget.space);
      await controller?.evaluateJavascript(source: script);
      print('✅ Download interceptor script injected for space: ${widget.space.id}');
    } catch (e) {
      print('❌ Error injecting download interceptor script: $e');
    }
  }

  void _handleDownloadCapture(dynamic messageData) async {
    try {
      final data = messageData is String ? json.decode(messageData) : messageData;
      print('📥 Download intercepted: ${data['file_name']}');
      print('🔗 File URL: ${data['file_url']}');
      print('📁 File type: ${data['file_type']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saving ${data['file_name']}...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final savedFile = await FileStorageService.saveFileFromData(
        space: widget.space,
        fileName: data['file_name'] ?? 'gradio_output',
        fileUrl: data['file_url'] ?? '',
        fileData: data['base64_data'],
      );

      if (savedFile != null) {
        final fileId = await SavedFilesDatabase.saveFile(savedFile);

        if (mounted && fileId > 0) {
          setState(() {
            pendingDownloadsCount++;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Saved ${savedFile.originalFileName}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FileViewerScreen(savedFile: savedFile),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to save file'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error handling download capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkForErrors() async {
    try {
      final result = await controller?.evaluateJavascript(source: '''
        (function() {
          var body = document.body.innerText.toLowerCase();
          if (body.includes('your space is in error') ||
              body.includes('space is in error') ||
              body.includes('error') && body.includes('check its status')) {
            return 'space_error';
          }
          if (body.includes('space not found') || body.includes('404')) {
            return 'not_found';
          }
          if (body.includes('building') || body.includes('cold start')) {
            return 'building';
          }
          return 'ok';
        })();
      ''');

      if (mounted && result != null && result.toString().replaceAll('"', '') != 'ok') {
        setState(() {
          hasError = true;
          switch (result.toString().replaceAll('"', '')) {
            case 'space_error':
              errorMessage = 'Space is currently experiencing issues';
              break;
            case 'not_found':
              errorMessage = 'Space not found';
              break;
            case 'building':
              errorMessage = 'Space is starting up';
              break;
            default:
              errorMessage = 'Unable to load space';
          }
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller?.reload();
            },
          ),
          IconButton(
            icon: pendingDownloadsCount > 0
                ? Badge(
                    label: Text(pendingDownloadsCount.toString()),
                    child: const Icon(Icons.outbox_outlined),
                  )
                : const Icon(Icons.outbox_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/outputs');
            },
            tooltip: pendingDownloadsCount > 0
                ? '$pendingDownloadsCount file${pendingDownloadsCount == 1 ? '' : 's'} saved'
                : 'Download files to save them',
          ),
        ],
        toolbarHeight: 56,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.space.url)),
            initialSettings: settings,
            onWebViewCreated: (InAppWebViewController webViewController) {
              controller = webViewController;

              controller!.addJavaScriptHandler(
                handlerName: 'saveDownloadedFile',
                callback: (args) {
                  if (args.isNotEmpty) {
                    _handleDownloadCapture(args[0]);
                  }
                },
              );
            },
            onLoadStart: (controller, url) {
              print('🔵 Page load started: $url');
              if (mounted) {
                setState(() {
                  isLoading = true;
                  hasError = false;
                  errorMessage = null;
                });
              }
            },
            onLoadStop: (controller, url) async {
              print('🔵 Page load stopped: $url');
              if (mounted) {
                setState(() {
                  isLoading = false;
                });

                await _injectDownloadInterceptorScript();
                await _checkForErrors();
              }
            },
            onProgressChanged: (controller, progress) {
              print('📊 Loading progress: $progress%');
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('🖥️ Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
            },
            onReceivedError: (controller, request, error) {
              print('❌ Received error: ${error.description}');
              if (mounted) {
                setState(() {
                  isLoading = false;
                  hasError = true;
                  errorMessage = error.description;
                });
              }
            },
            onReceivedHttpError: (controller, request, errorResponse) async {
              print('❌ HTTP error: ${errorResponse.statusCode} for ${request.url}');

              // If we get a 404 on the .hf.space URL, try the fallback spaces URL
              if (errorResponse.statusCode == 404 &&
                  request.url.toString().contains('.hf.space')) {
                final fallbackUrl = 'https://huggingface.co/spaces/${widget.space.id}';
                print('⚠️ 404 on .hf.space URL, trying fallback: $fallbackUrl');

                await controller.loadUrl(
                  urlRequest: URLRequest(url: WebUri(fallbackUrl)),
                );
                return;
              }
            },
            onPermissionRequest: (controller, request) async {
              print('🔐 Permission request: ${request.resources}');
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {

              final host = challenge.protectionSpace.host;
              if (host.endsWith('.hf.space') ||
                  host.endsWith('huggingface.co') ||
                  host.endsWith('.huggingface.co')) {
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED
                );
              }

              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.CANCEL
              );
            },
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (hasError)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        errorMessage ?? 'Failed to load space',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please try again or check if the space is available at ${widget.space.url}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                hasError = false;
                                isLoading = true;
                              });
                              controller?.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(widget.space.url);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Open in Browser'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
