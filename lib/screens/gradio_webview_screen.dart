import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/huggingface_space.dart';

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

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
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
      ..loadRequest(Uri.parse(widget.space.url));
  }

  Future<void> _checkForErrors() async {
    try {
      // Check if page contains common error messages
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
      // JavaScript execution failed, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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