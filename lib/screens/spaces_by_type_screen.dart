import 'package:flutter/material.dart';
import '../models/huggingface_space.dart';
import '../models/space_type.dart';
import '../services/huggingface_service.dart';
import 'gradio_webview_screen.dart';

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
          allSpaces = typeSpaces;
          spaces = typeSpaces.take(50).toList(); // Initially load 20 spaces
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
        backgroundColor: color.withOpacity(0.1),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
                      },
                    ),
    );
  }
}