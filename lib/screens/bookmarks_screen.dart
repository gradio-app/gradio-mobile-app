import 'package:flutter/material.dart';
import '../models/huggingface_space.dart';
import '../services/huggingface_service.dart';
import '../services/hf_oauth_service.dart';
import 'gradio_webview_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  bool isLoggedIn = false;
  HuggingFaceUser? currentUser;
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
    _checkAuthentication();
  }

  void _onTabChange() {
    // Tab change listener - could be used for analytics or specific tab logic if needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      isLoading = true;
    });

    try {
      final isAuth = await HFOAuthService.isAuthenticated();
      if (isAuth) {
        final user = await HFOAuthService.getCurrentUser();
        if (user != null) {
          setState(() {
            currentUser = user;
            isLoggedIn = true;
          });
          await _fetchUserSpaces(user.username);
        }
      }
    } catch (e) {
      print('Authentication check error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(BookmarksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when widget is updated (e.g., when navigating back to this screen)
    if (isLoggedIn && currentUser != null) {
      _refreshUserSpaces();
    }
  }

  Future<void> _fetchUserSpaces(String username, {bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final accessToken = await HFOAuthService.getAccessToken();

      // Fetch both liked and created spaces in parallel
      final futures = await Future.wait([
        HuggingFaceService.getUserLikedSpaces(username, accessToken: accessToken),
        HuggingFaceService.getUserCreatedSpaces(username),
      ]);

      setState(() {
        likedSpaces = futures[0];
        createdSpaces = futures[1];
        isLoading = false;
      });

      // Only show success message on first load (when loading indicator was shown)
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
    if (currentUser != null) {
      await _fetchUserSpaces(currentUser!.username, showLoadingIndicator: false);
    }
  }

  Future<void> _signInWithOAuth() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = await HFOAuthService.login();
      if (user != null) {
        setState(() {
          currentUser = user;
          isLoggedIn = true;
        });

        await _fetchUserSpaces(user.username);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user.username}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        error = 'Login failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await HFOAuthService.logout();
    setState(() {
      isLoggedIn = false;
      currentUser = null;
      likedSpaces.clear();
      createdSpaces.clear();
      error = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
    }
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
              onPressed: isLoading ? null : _signInWithOAuth,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No public liked spaces found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Only public likes are shown here.\n\nIf you have liked spaces set to private, they won\'t appear in this list.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Open user's profile page in browser
                // This would require url_launcher
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('View on HuggingFace'),
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
              onPressed: isLoading ? null : _signInWithOAuth,
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
            onPressed: _logout,
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
                          if (currentUser != null) {
                            _fetchUserSpaces(currentUser!.username);
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

