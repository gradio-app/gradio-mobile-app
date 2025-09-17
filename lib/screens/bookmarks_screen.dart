import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/huggingface_space.dart';
import '../services/huggingface_service.dart';
import 'gradio_webview_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  bool isLoggedIn = false;
  String? username;
  String? accessToken;
  List<HuggingFaceSpace> likedSpaces = [];
  List<HuggingFaceSpace> createdSpaces = [];
  bool isLoading = false;
  String? error;

  // Tab controller for Liked vs Created Spaces
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    _checkSavedSession();
  }

  void _onTabChange() {
    // Tab change listener - could be used for analytics or specific tab logic if needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('hf_username');
    final savedAccessToken = prefs.getString('hf_access_token');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      accessToken = savedAccessToken;
      _fetchUserSpaces(savedUsername);
    }
  }

  @override
  void didUpdateWidget(BookmarksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when widget is updated (e.g., when navigating back to this screen)
    if (isLoggedIn && username != null) {
      _refreshUserSpaces();
    }
  }

  Future<void> _fetchUserSpaces(String enteredUsername, {bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        error = null;
        username = enteredUsername;
      });
    }

    try {
      // Fetch both liked and created spaces in parallel
      final futures = await Future.wait([
        HuggingFaceService.getUserLikedSpaces(enteredUsername, accessToken: accessToken),
        HuggingFaceService.getUserCreatedSpaces(enteredUsername),
      ]);

      setState(() {
        likedSpaces = futures[0];
        createdSpaces = futures[1];
        isLoggedIn = true;
        isLoading = false;
        username = enteredUsername;
      });

      await _saveSession(enteredUsername, token: accessToken);

      if (mounted && showLoadingIndicator) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${futures[0].length} liked and ${futures[1].length} created spaces!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
        if (showLoadingIndicator) {
          isLoggedIn = false;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading spaces: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshUserSpaces() async {
    if (username != null) {
      await _fetchUserSpaces(username!, showLoadingIndicator: false);
    }
  }

  Future<void> _saveSession(String username, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_username', username);
    if (token != null && token.isNotEmpty) {
      await prefs.setString('hf_access_token', token);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hf_username');
    await prefs.remove('hf_access_token');
  }

  void _signInToHuggingFace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return _WebViewLoginSheet(
          onLoginSuccess: (String detectedUsername, {String? token}) {
            Navigator.of(context).pop();
            if (detectedUsername.isNotEmpty) {
              accessToken = token;
              _fetchUserSpaces(detectedUsername);
            } else {
              // Show error if username detection fails
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not detect username automatically. Please try signing in again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onLoginCancelled: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }



  String _formatLastModified(DateTime lastModified) {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Widget _buildSpaceCard(HuggingFaceSpace space) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (space.emoji != null) ...[
              Text(
                space.emoji!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                space.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'by ${space.author}',
              style: const TextStyle(fontSize: 16),
            ),
            if (space.description != null)
              Text(
                space.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 95,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 3),
                  Text(
                    '${space.likes}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  space.status ?? 'Running',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (space.lastModified != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    _formatLastModified(space.lastModified!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        isThreeLine: space.description != null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GradioWebViewScreen(
                space: space,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikedSpacesTab() {
    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to view your spaces',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Connect to your Hugging Face account to view spaces you\'ve liked',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _signInToHuggingFace,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Hugging Face'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (likedSpaces.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No liked spaces found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Like some Gradio spaces on Hugging Face to see them here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUserSpaces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: likedSpaces.length,
        itemBuilder: (context, index) {
          return _buildSpaceCard(likedSpaces[index]);
        },
      ),
    );
  }

  Widget _buildCreatedSpacesTab() {
    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to view your spaces',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Connect to your Hugging Face account to view your created Gradio spaces',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _signInToHuggingFace,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Hugging Face'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (createdSpaces.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Gradio spaces found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Create some Gradio spaces on Hugging Face to see them here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUserSpaces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: createdSpaces.length,
        itemBuilder: (context, index) {
          return _buildSpaceCard(createdSpaces[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: isLoggedIn ? [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _clearSession();
              setState(() {
                isLoggedIn = false;
                username = null;
                accessToken = null;
                likedSpaces.clear();
                createdSpaces.clear();
                error = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
              }
            },
          ),
        ] : null,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Liked',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Created',
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (username != null) {
                            _fetchUserSpaces(username!);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLikedSpacesTab(),
                    _buildCreatedSpacesTab(),
                  ],
                ),
    );
  }
}

// Keep the existing WebView login implementation
class _WebViewLoginSheet extends StatefulWidget {
  final Function(String, {String? token}) onLoginSuccess;
  final VoidCallback onLoginCancelled;

  const _WebViewLoginSheet({
    required this.onLoginSuccess,
    required this.onLoginCancelled,
  });

  @override
  State<_WebViewLoginSheet> createState() => _WebViewLoginSheetState();
}

class _WebViewLoginSheetState extends State<_WebViewLoginSheet> {
  late final WebViewController controller;
  bool isLoading = true;
  String? detectedUsername;
  String? detectedAccessToken;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
        'Mobile/15E148 Safari/604.1 GradioMobileApp/1.0'
      )
      ..enableZoom(true)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterLogin',
        onMessageReceived: (JavaScriptMessage message) {
          print('WebView message received: ${message.message}'); // Debug

          if (message.message.startsWith('oauth_success:')) {
            try {
              final oauthDataJson = message.message.substring(13).trim();
              print('Raw JSON data: $oauthDataJson'); // Debug

              final oauthData = json.decode(oauthDataJson);

              final extractedUsername = oauthData['username'];
              final extractedAccessToken = oauthData['accessToken'];

              print('Extracted username: $extractedUsername'); // Debug

              final invalidUsernames = [
                'enterprise', 'welcome', 'home', 'dashboard', 'profile',
                'account', 'user', 'settings', 'v1', 'api', 'docs', 'datasets',
                'models', 'spaces', 'papers', 'login', 'join', 'blog',
                'pricing', 'inference-endpoints', 'hub', 'tasks', 'learn',
                'organizations', 'new'
              ];

              if (extractedUsername != null &&
                  extractedUsername.isNotEmpty &&
                  !invalidUsernames.contains(extractedUsername.toLowerCase()) &&
                  extractedUsername.length >= 2 &&
                  extractedUsername.length <= 39 &&
                  RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(extractedUsername)) {
                detectedUsername = extractedUsername;
                detectedAccessToken = extractedAccessToken;

                print('Valid username detected: $extractedUsername'); // Debug

                if (mounted) {
                  widget.onLoginSuccess(extractedUsername, token: extractedAccessToken);
                }
              } else {
                print('Invalid username: $extractedUsername (in invalid list: ${invalidUsernames.contains(extractedUsername?.toLowerCase())})'); // Debug
                detectedUsername = null;
                detectedAccessToken = null;
              }

            } catch (e) {
              print('Error parsing OAuth success data: $e');
              print('Raw message: ${message.message}');
            }
          } else if (message.message.startsWith('oauth_failed:')) {
            print('OAuth failed: ${message.message}'); // Debug
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started: $url'); // Debug
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('Page finished: $url'); // Debug
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              _checkLoginStatus(url);
            }
          },
          onUrlChange: (UrlChange change) {
            print('URL changed: ${change.url}'); // Debug
            if (change.url != null) {
              _checkLoginStatus(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://huggingface.co/login'));
  }

  Future<void> _checkLoginStatus(String url) async {
    if (url.contains('huggingface.co') && !url.contains('/login') && !url.contains('/join')) {
      await controller.runJavaScript(r'''
        (async function() {
          try {
            console.log('Checking login status for URL:', window.location.href);

            // Primary method: get user info from the whoami API (like HF Python client)
            var response = await fetch('/api/whoami', {
              method: 'GET',
              credentials: 'include',
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
            });

            console.log('Whoami response status:', response.status);

            if (response.ok) {
              var userData = await response.json();
              console.log('User data received:', userData);

              // Try different possible username fields
              var detectedUsername = userData.name || userData.username || userData.login;

              if (detectedUsername) {
                console.log('Username detected from whoami:', detectedUsername);
                FlutterLogin.postMessage('oauth_success:' + JSON.stringify({
                  accessToken: userData.access_token || null,
                  userInfo: userData,
                  username: detectedUsername
                }));
                return;
              }
            }

            // Secondary: Check if we're on a user's profile page
            if (window.location.pathname.startsWith('/') && window.location.pathname !== '/') {
              var pathParts = window.location.pathname.split('/').filter(part => part);
              if (pathParts.length >= 1) {
                var potentialUsername = pathParts[0];
                var invalidPaths = [
                  'spaces', 'models', 'datasets', 'docs', 'join', 'login', 'settings',
                  'organizations', 'new', 'welcome', 'enterprise', 'pricing', 'blog',
                  'tasks', 'learn', 'hub', 'api', 'papers', 'inference-endpoints'
                ];

                if (!invalidPaths.includes(potentialUsername.toLowerCase()) &&
                    potentialUsername.length >= 2 && potentialUsername.length <= 39 &&
                    /^[a-zA-Z0-9_-]+$/.test(potentialUsername)) {
                  console.log('Username detected from URL path:', potentialUsername);
                  FlutterLogin.postMessage('oauth_success:' + JSON.stringify({
                    accessToken: null,
                    userInfo: { name: potentialUsername },
                    username: potentialUsername
                  }));
                  return;
                }
              }
            }

          } catch (e) {
            console.log('Login check failed:', e);
          }

          console.log('No username detected, failing');
          FlutterLogin.postMessage('oauth_failed:no_user_data');
        })();
      ''');

      Future.delayed(const Duration(milliseconds: 5000), () {
        if (mounted && detectedUsername?.isEmpty != false) {
          widget.onLoginSuccess('', token: detectedAccessToken);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sign in to Hugging Face',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onLoginCancelled,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: controller),
                if (isLoading)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading Hugging Face login...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}