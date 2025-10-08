import 'package:flutter/material.dart';
import '../models/huggingface_space.dart';
import '../services/huggingface_service.dart';
import '../services/hf_oauth_service.dart';
import 'gradio_webview_screen.dart';
import '../widgets/space_card.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  bool isLoggedIn = false;
  HuggingFaceUser? currentUser;
  List<HuggingFaceSpace> allLikedSpaces = [];
  List<HuggingFaceSpace> displayedLikedSpaces = [];
  List<HuggingFaceSpace> createdSpaces = [];
  bool isLoading = false;
  bool isLoadingMoreLiked = false;
  String? error;

  final ScrollController _likedScrollController = ScrollController();
  String _sortBy = 'likes';
  String _currentFilter = 'liked';

  @override
  void initState() {
    super.initState();
    _likedScrollController.addListener(_onLikedScroll);
    _checkAuthentication();
  }

  void _onLikedScroll() {
    if (_likedScrollController.position.pixels >= _likedScrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMoreLiked && displayedLikedSpaces.length < allLikedSpaces.length) {
        _loadMoreLikedSpaces();
      }
    }
  }

  void _loadMoreLikedSpaces() {
    if (isLoadingMoreLiked || displayedLikedSpaces.length >= allLikedSpaces.length) return;

    setState(() {
      isLoadingMoreLiked = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final currentLength = displayedLikedSpaces.length;
          final additionalSpaces = allLikedSpaces.skip(currentLength).take(50).toList();
          displayedLikedSpaces.addAll(additionalSpaces);
          isLoadingMoreLiked = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _likedScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final isAuth = await HFOAuthService.isAuthenticated();
      if (isAuth) {
        final user = await HFOAuthService.getCurrentUser();
        if (user != null && mounted) {
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(BookmarksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isLoggedIn && currentUser != null) {
      _refreshUserSpaces();
    }
  }

  Future<void> _fetchUserSpaces(String username, {bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator && mounted) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final accessToken = await HFOAuthService.getAccessToken();

      final futures = await Future.wait([
        HuggingFaceService.getUserLikedSpaces(username, accessToken: accessToken),
        HuggingFaceService.getUserCreatedSpaces(username),
      ]);

      if (mounted) {
        setState(() {
          allLikedSpaces = _applySort(futures[0]);
          displayedLikedSpaces = allLikedSpaces.take(50).toList();
          createdSpaces = _applySort(futures[1]);
          isLoading = false;
        });
      }

      if (mounted && showLoadingIndicator) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${futures[0].length} liked and ${futures[1].length} created spaces!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }

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

  List<HuggingFaceSpace> _applySort(List<HuggingFaceSpace> list) {
    final result = List<HuggingFaceSpace>.from(list);
    switch (_sortBy) {
      case 'liked':
        result.sort((a, b) {
          final aTime = a.likedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.likedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;
      case 'recent':
        result.sort((a, b) {
          final aTime = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;
      case 'name':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'likes':
      default:
        result.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return result;
  }

  Future<void> _refreshUserSpaces() async {
    if (currentUser != null) {
      await _fetchUserSpaces(currentUser!.username, showLoadingIndicator: false);
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sort by',
          style: GoogleFonts.sourceSans3(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(context, 'liked', 'Most recent likes', Icons.favorite),
            const SizedBox(height: 8),
            _buildSortOption(context, 'likes', 'Most liked', Icons.favorite_border),
            const SizedBox(height: 8),
            _buildSortOption(context, 'recent', 'Recently updated', Icons.schedule),
            const SizedBox(height: 8),
            _buildSortOption(context, 'name', 'Name A–Z', Icons.sort_by_alpha),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
          allLikedSpaces = _applySort(allLikedSpaces);
          createdSpaces = _applySort(createdSpaces);
          displayedLikedSpaces = allLikedSpaces.take(displayedLikedSpaces.length).toList();
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sourceSans3(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Filter by',
          style: GoogleFonts.sourceSans3(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(context, 'all', 'All Spaces', Icons.apps),
            const SizedBox(height: 8),
            _buildFilterOption(context, 'liked', 'Liked Only', Icons.favorite),
            const SizedBox(height: 8),
            _buildFilterOption(context, 'created', 'Created Only', Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String value, String label, IconData icon) {
    final isSelected = _currentFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _currentFilter = value;
          _updateDisplayedSpaces();
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sourceSans3(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  void _updateDisplayedSpaces() {
    switch (_currentFilter) {
      case 'liked':
        displayedLikedSpaces = allLikedSpaces.take(displayedLikedSpaces.length).toList();
        break;
      case 'created':
        displayedLikedSpaces = createdSpaces.take(displayedLikedSpaces.length).toList();
        break;
      case 'all':
      default:
        final allSpaces = [...allLikedSpaces, ...createdSpaces];
        displayedLikedSpaces = allSpaces.take(displayedLikedSpaces.length).toList();
        break;
    }
  }

  Future<void> _signInWithOAuth() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final user = await HFOAuthService.login();
      if (user != null && mounted) {
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
      if (mounted) {
        setState(() {
          error = 'Login failed: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await HFOAuthService.logout();
    setState(() {
      isLoggedIn = false;
      currentUser = null;
      allLikedSpaces.clear();
      displayedLikedSpaces.clear();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SpaceCard(
        space: space,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GradioWebViewScreen(space: space)),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _signInWithOAuth,
                icon: const Text('🤗', style: TextStyle(fontSize: 18)),
                label: Text(
                  'Sign in with Hugging Face',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (allLikedSpaces.isEmpty) {
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
        controller: _likedScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: displayedLikedSpaces.length + (isLoadingMoreLiked ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayedLikedSpaces.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildSpaceCard(displayedLikedSpaces[index]);
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _signInWithOAuth,
                icon: const Text('🤗', style: TextStyle(fontSize: 18)),
                label: Text(
                  'Sign in with Hugging Face',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.transparent,
                ),
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
        title: Text(
          'Favorites',
          style: GoogleFonts.sourceSans3(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: isLoggedIn ? [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ] : null,
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
              : _buildLikedSpacesTab(),
    );
  }
}

