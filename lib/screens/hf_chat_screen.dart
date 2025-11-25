import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

class HFChatScreen extends StatefulWidget {
  const HFChatScreen({super.key});

  @override
  State<HFChatScreen> createState() => _HFChatScreenState();
}

class _HFChatScreenState extends State<HFChatScreen> with AutomaticKeepAliveClientMixin {
  InAppWebViewController? controller;
  bool isLoading = true;
  double loadingProgress = 0;

  // Keep the state alive so login persists when switching tabs
  @override
  bool get wantKeepAlive => true;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useOnDownloadStart: true,
    useOnLoadResource: false,
    clearCache: false,
    cacheEnabled: true,
    thirdPartyCookiesEnabled: true,
    supportZoom: true,
    builtInZoomControls: true,
    displayZoomControls: false,
    sharedCookiesEnabled: true, // Share cookies with other webviews
  );

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HuggingChat',
          style: GoogleFonts.sourceSans3(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (controller != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller?.reload();
              },
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (await controller?.canGoBack() ?? false) {
                  controller?.goBack();
                }
              },
              tooltip: 'Back',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () async {
                if (await controller?.canGoForward() ?? false) {
                  controller?.goForward();
                }
              },
              tooltip: 'Forward',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://huggingface.co/chat/'),
            ),
            initialSettings: settings,
            onWebViewCreated: (InAppWebViewController webViewController) {
              controller = webViewController;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                loadingProgress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                isLoading = false;
              });
            },
          ),
          if (isLoading)
            LinearProgressIndicator(
              value: loadingProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
        ],
      ),
    );
  }
}
