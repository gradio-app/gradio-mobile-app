import 'package:flutter/material.dart';
import '../models/huggingface_space.dart';
import '../services/huggingface_service.dart';
import 'gradio_webview_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<HuggingFaceSpace> spaces = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    loadTrendingSpaces();
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
      setState(() {
        isLoading = true;
        error = null;
        isSearching = false;
      });
      final trendingSpaces = await HuggingFaceService.getTrendingSpaces();
      setState(() {
        spaces = trendingSpaces;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> searchSpaces(String query) async {
    if (query.trim().isEmpty) {
      loadTrendingSpaces();
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
        isSearching = true;
      });
      final searchResults = await HuggingFaceService.searchSpaces(query);
      setState(() {
        spaces = searchResults;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Container(
          height: 40,
          child: TextField(
            controller: _searchController,
            onSubmitted: searchSpaces,
            onChanged: (value) {
              if (value.isEmpty) {
                loadTrendingSpaces();
              }
            },
            decoration: InputDecoration(
              hintText: 'Search for Gradio spaces...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        loadTrendingSpaces();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
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
                        onPressed: loadTrendingSpaces,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
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