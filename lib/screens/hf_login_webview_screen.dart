import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hf_oauth_service.dart';

class HFLoginWebviewScreen extends StatefulWidget {
  const HFLoginWebviewScreen({super.key});

  @override
  State<HFLoginWebviewScreen> createState() => _HFLoginWebviewScreenState();
}

class _HFLoginWebviewScreenState extends State<HFLoginWebviewScreen> {
  InAppWebViewController? controller;
  bool isLoading = true;
  double loadingProgress = 0;
  bool _isCheckingLogin = false;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    clearCache: false,
    cacheEnabled: true,
    thirdPartyCookiesEnabled: true,
    sharedCookiesEnabled: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign in with Hugging Face',
          style: GoogleFonts.sourceSans3(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://huggingface.co/login'),
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
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false;
              });

              // Check if user has completed login
              if (url != null) {
                await _checkIfLoggedIn(url.toString());
              }
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
        ],
      ),
    );
  }

  Future<void> _checkIfLoggedIn(String url) async {
    // Don't check if we're on login page or already checking
    if (_isCheckingLogin) return;
    if (url.contains('/login') || url.contains('/join')) return;

    // Check if we landed on a logged-in page (not login/join page)
    if (url.contains('huggingface.co') && !url.contains('/login') && !url.contains('/join')) {
      _isCheckingLogin = true;

      try {
        // Check for session cookies
        final cookieManager = CookieManager.instance();
        final cookies = await cookieManager.getCookies(
          url: WebUri('https://huggingface.co'),
        );

        // Debug: Print all cookies
        print('=== HuggingFace Cookies ===');
        for (final cookie in cookies) {
          print('Cookie: ${cookie.name} = ${cookie.value.substring(0, cookie.value.length > 20 ? 20 : cookie.value.length)}...');
        }

        // Look for authentication cookies
        // HuggingFace uses 'token' for API and 'hf-chat' for chat
        String? token;
        bool hasHfChat = false;
        for (final cookie in cookies) {
          if (cookie.name == 'token') {
            token = cookie.value;
          }
          if (cookie.name == 'hf-chat') {
            hasHfChat = true;
          }
        }

        print('Token found: ${token != null}, hf-chat found: $hasHfChat');

        if (token != null && token.isNotEmpty) {
          // User is logged in! Fetch user info using the token
          final user = await HFOAuthService.loginWithToken(token);

          if (user != null && mounted) {
            // Navigate to /chat briefly to initialize chat cookies
            if (!hasHfChat && !url.contains('/chat')) {
              print('Navigating to /chat to initialize chat session...');
              await controller?.loadUrl(
                urlRequest: URLRequest(url: WebUri('https://huggingface.co/chat/')),
              );
              // Don't pop yet, wait for chat page to load
              _isCheckingLogin = false;
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, ${user.username}!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(user);
            return;
          }
        }

        // Alternative: Check if we can get user info from the page
        // This happens when user completes login and lands on their profile or home
        if (url == 'https://huggingface.co/' || url.contains('huggingface.co/settings') || url.contains('/chat')) {
          // Try to fetch user info using cookies
          final user = await _fetchUserFromCookies();
          if (user != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, ${user.username}!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(user);
            return;
          }
        }
      } catch (e) {
        print('Error checking login status: $e');
      } finally {
        _isCheckingLogin = false;
      }
    }
  }

  Future<HuggingFaceUser?> _fetchUserFromCookies() async {
    try {
      // Get all cookies for HuggingFace
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(
        url: WebUri('https://huggingface.co'),
      );

      // Find the token cookie
      String? token;
      for (final cookie in cookies) {
        if (cookie.name == 'token') {
          token = cookie.value;
          break;
        }
      }

      if (token != null && token.isNotEmpty) {
        return await HFOAuthService.loginWithToken(token);
      }

      return null;
    } catch (e) {
      print('Error fetching user from cookies: $e');
      return null;
    }
  }
}
