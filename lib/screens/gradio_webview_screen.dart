import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  int pendingDownloadsCount = 0;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                hasError = false;
                errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });

              // Inject download interceptor script
              _injectDownloadInterceptorScript();

              // Check if the page contains error messages
              _checkForErrors();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
                hasError = true;
                errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'saveDownloadedFile',
        onMessageReceived: (JavaScriptMessage message) {
          _handleDownloadCapture(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.space.url));
  }

  Future<void> _injectDownloadInterceptorScript() async {
    try {
      final script = GradioDownloadInterceptor.generateInterceptorScript(widget.space);
      await controller.runJavaScript(script);
      print('✅ Download interceptor script injected for space: ${widget.space.id}');
    } catch (e) {
      print('❌ Error injecting download interceptor script: $e');
    }
  }

  void _handleDownloadCapture(String messageData) async {
    try {
      final data = json.decode(messageData);
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FileViewerScreen(savedFile: savedFile),
                    ),
                  );
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
      final result = await controller.runJavaScriptReturningResult('''
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

      if (mounted && result.toString().replaceAll('"', '') != 'ok') {
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
              controller.reload();
            },
          ),
          IconButton(
            icon: pendingDownloadsCount > 0
                ? Badge(
                    label: Text(pendingDownloadsCount.toString()),
                    child: const Icon(Icons.download_done),
                  )
                : const Icon(Icons.download, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(), // Go to outputs tab
            tooltip: pendingDownloadsCount > 0
                ? '$pendingDownloadsCount file${pendingDownloadsCount == 1 ? '' : 's'} saved'
                : 'Download files to save them',
          ),
        ],
        toolbarHeight: 56,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
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
                        errorMessage ?? 'Unable to load space',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The Gradio space "${widget.space.name}" is currently unavailable.',
                        style: TextStyle(
                          fontSize: 16,
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
                              controller.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('https://huggingface.co/spaces/${widget.space.id}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Open on HF'),
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