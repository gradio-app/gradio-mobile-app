import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/huggingface_space.dart';
import '../models/space_type.dart';
import '../services/huggingface_service.dart';
import 'gradio_webview_screen.dart';
import '../widgets/space_card.dart';

class SpacesByTypeScreen extends StatefulWidget {
  final SpaceType spaceType;

  const SpacesByTypeScreen({super.key, required this.spaceType});

  @override
  State<SpacesByTypeScreen> createState() => _SpacesByTypeScreenState();
}

class _SpacesByTypeScreenState extends State<SpacesByTypeScreen> {
  List<HuggingFaceSpace> spaces = [];
  List<HuggingFaceSpace> allSpaces = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'likes';

  @override
  void initState() {
    super.initState();
    loadSpacesByType();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && !isLoading && spaces.length < allSpaces.length) {
        loadMoreSpaces();
      }
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
            _buildSortOption(context, 'likes', 'Most liked', Icons.favorite),
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
          allSpaces = _applySort(allSpaces);
          spaces = allSpaces.take(spaces.length).toList();
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

  Future<void> loadSpacesByType() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }
      final typeSpaces = await HuggingFaceService.getSpacesByType(widget.spaceType.id);
      if (mounted) {
        setState(() {
          allSpaces = _applySort(typeSpaces);
          spaces = allSpaces.take(50).toList();
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

  Future<void> loadMoreSpaces() async {
    if (isLoadingMore || spaces.length >= allSpaces.length) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          final currentLength = spaces.length;
          final additionalSpaces = allSpaces.skip(currentLength).take(50).toList();
          spaces.addAll(additionalSpaces);
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
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

  Color _getColor() {
    try {
      return Color(int.parse(widget.spaceType.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.spaceType.icon,
              size: 24,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.spaceType.name,
                style: GoogleFonts.sourceSans3(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
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
                        onPressed: loadSpacesByType,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : spaces.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.spaceType.icon,
                            size: 64,
                            color: color.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.spaceType.name.toLowerCase()} spaces found',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try again later as new spaces are added regularly',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: spaces.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= spaces.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

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