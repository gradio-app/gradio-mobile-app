import 'package:flutter/material.dart';
import '../models/huggingface_space.dart';
import '../models/space_type.dart';
import '../services/huggingface_service.dart';
import '../widgets/space_type_card.dart';
import '../widgets/space_card.dart';
import 'gradio_webview_screen.dart';
import 'spaces_by_type_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<HuggingFaceSpace> spaces = [];
  bool isLoading = false;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  bool showSpaceTypes = true;
  String _sortBy = 'likes'; // likes | recent | name

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadTrendingSpaces() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          error = null;
          isSearching = false;
        });
      }
      final trendingSpaces = await HuggingFaceService.getTrendingSpaces();
      if (mounted) {
        setState(() {
          spaces = _applySort(trendingSpaces);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> searchSpaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        showSpaceTypes = true;
        isSearching = false;
        spaces = [];
        error = null;
      });
      return;
    }

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          error = null;
          isSearching = true;
          showSpaceTypes = false;
        });
      }
      final searchResults = await HuggingFaceService.searchSpaces(query);
      if (mounted) {
        setState(() {
          spaces = _applySort(searchResults);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  List<HuggingFaceSpace> _applySort(List<HuggingFaceSpace> list) {
    final result = List<HuggingFaceSpace>.from(list);
    switch (_sortBy) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spaces',
          style: GoogleFonts.sourceSans3(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                spaces = _applySort(spaces);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'likes', child: Text('Most liked')),
              PopupMenuItem(value: 'recent', child: Text('Recently updated')),
              PopupMenuItem(value: 'name', child: Text('Name A–Z')),
            ],
          ),
        ],
      ),
      body: showSpaceTypes
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: SpaceType.spaceTypes.length,
              itemBuilder: (context, index) {
                final spaceType = SpaceType.spaceTypes[index];
                return SpaceTypeCard(
                  spaceType: spaceType,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpacesByTypeScreen(spaceType: spaceType),
                      ),
                    );
                  },
                );
              },
            )
          : isLoading
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
                              setState(() {
                                showSpaceTypes = true;
                                isSearching = false;
                                spaces = [];
                                error = null;
                              });
                            },
                            child: const Text('Back to Categories'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: spaces.length,
                      itemBuilder: (context, index) {
                        final space = spaces[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SpaceCard(
                            space: space,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GradioWebViewScreen(space: space),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}