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
  bool _showDoneButton = false;

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
        actions: _showDoneButton
            ? [
                TextButton(
                  onPressed: _finishLogin,
                  child: Text(
                    'Done',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ]
            : null,
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

  Future<void> _finishLogin() async {
    if (_isCheckingLogin) return;
    _isCheckingLogin = true;

    try {
      final user = await _fetchUserFromCookies();
      if (user != null && mounted) {
        Navigator.of(context).pop(user);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to complete sign-in. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isCheckingLogin = false;
    }
  }

  Future<void> _checkIfLoggedIn(String url) async {
    // Don't check if we're on login page or already checking
    if (_isCheckingLogin) return;
    if (url.contains('/login') || url.contains('/join')) {
      // Hide the done button on login/join pages
      if (_showDoneButton && mounted) {
        setState(() {
          _showDoneButton = false;
        });
      }
      return;
    }

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
          // User is logged in! The token is a session cookie, not an OAuth token
          // Try to fetch user info using the session cookie
          final user = await HFOAuthService.loginWithSessionCookie(token);

          if (user != null && mounted) {
            // Show the Done button as a fallback
            setState(() {
              _showDoneButton = true;
            });

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

            // Add a small delay to ensure cookies are fully set
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${user.username}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              // Use Navigator.of(context).pop to ensure we return to the previous screen
              Navigator.of(context).pop(user);
            }
            return;
          }
        }

        // Alternative: Check if we can get user info from the page
        // This happens when user completes login and lands on their profile or home
        if (url == 'https://huggingface.co/' || url.contains('huggingface.co/settings') || url.contains('/chat')) {
          // Try to fetch user info using cookies
          final user = await _fetchUserFromCookies();
          if (user != null && mounted) {
            // Add a small delay to ensure cookies are fully set
            await Future.delayed(const Duration(milliseconds: 300));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${user.username}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop(user);
            }
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

      // Find the token cookie - this is a session cookie, not an OAuth token
      String? sessionToken;
      for (final cookie in cookies) {
        if (cookie.name == 'token') {
          sessionToken = cookie.value;
          break;
        }
      }

      if (sessionToken == null || sessionToken.isEmpty) {
        print('No session token found in cookies');
        return null;
      }

      print('Session token found, attempting to fetch user info from page...');

      // Use JavaScript to get user info from the page
      if (controller != null) {
        try {
          // Try to get username from the page's data
          final result = await controller!.evaluateJavascript(source: '''
            (function() {
              // Try to get username from various places on the page
              var username = null;

              // Method 1: Check for user menu/profile link
              var profileLink = document.querySelector('a[href^="/"]');
              if (profileLink) {
                var href = profileLink.getAttribute('href');
                if (href && href.startsWith('/') && !href.startsWith('//') && href.length > 1 && !href.startsWith('/settings') && !href.startsWith('/chat')) {
                  username = href.substring(1).split('/')[0];
                }
              }

              // Method 2: Check for username in page scripts or data
              var scripts = document.getElementsByTagName('script');
              for (var i = 0; i < scripts.length; i++) {
                var content = scripts[i].textContent;
                if (content && content.includes('"username"')) {
                  var match = content.match(/"username"\\s*:\\s*"([^"]+)"/);
                  if (match && match[1]) {
                    username = match[1];
                    break;
                  }
                }
              }

              return username;
            })();
          ''');

          print('JavaScript extraction result: $result');

          if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
            final username = result.toString();
            print('Extracted username from page: $username');

            // Create a HuggingFaceUser with the session token
            // We'll save the session token for making authenticated API requests
            final user = HuggingFaceUser(username: username);

            // Save the session token as if it were an access token
            // This will allow the app to use it for authenticated requests with cookies
            await HFOAuthService.loginWithSessionToken(sessionToken, user);

            return user;
          }
        } catch (e) {
          print('JavaScript extraction failed: $e');
        }
      }

      // Fallback: Try to fetch user info using the session token as a cookie
      // Make a request to whoami endpoint with cookies
      print('Attempting to fetch user info using session cookies...');
      final user = await HFOAuthService.loginWithSessionCookie(sessionToken);
      return user;
    } catch (e) {
      print('Error fetching user from cookies: $e');
      return null;
    }
  }
}
