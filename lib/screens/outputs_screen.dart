import 'package:flutter/material.dart';
import 'dart:io';
import '../models/saved_generated_file.dart';
import '../services/saved_files_database.dart';
import '../services/file_storage_service.dart';
import 'file_viewer_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OutputsScreen extends StatefulWidget {
  const OutputsScreen({super.key});

  @override
  State<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends State<OutputsScreen> {
  List<SavedGeneratedFile> _savedFiles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFileType = 'all';

  final List<String> _fileTypes = ['all', 'image', 'audio', 'video', 'document', 'data'];

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
  }

  Future<void> _loadSavedFiles() async {
    try {
      final files = await SavedFilesDatabase.getAllFiles();
      if (mounted) {
        setState(() {
          _savedFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SavedGeneratedFile> get _filteredFiles {
    var filtered = _savedFiles;

    if (_selectedFileType != 'all') {
      filtered = filtered.where((file) => file.fileType == _selectedFileType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((file) {
        return file.spaceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               file.originalFileName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               file.spaceId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (file.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Files',
          style: GoogleFonts.sourceSans3(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadSavedFiles();
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'storage_info',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Storage Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_savedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),

          if (_savedFiles.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _fileTypes.length,
                itemBuilder: (context, index) {
                  final fileType = _fileTypes[index];
                  final isSelected = _selectedFileType == fileType;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getFileTypeLabel(fileType)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFileType = fileType;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: _getFileTypeColor(fileType).withOpacity(0.2),
                      checkmarkColor: _getFileTypeColor(fileType),
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedFiles.isEmpty
                    ? _buildEmptyState()
                    : _filteredFiles.isEmpty
                        ? _buildNoResultsState()
                        : _buildFilesGrid(),
          ),
        ],
      ),
    );
  }

  String _getFileTypeLabel(String fileType) {
    switch (fileType) {
      case 'all': return 'All';
      case 'image': return 'Images';
      case 'audio': return 'Audio';
      case 'video': return 'Videos';
      case 'document': return 'Documents';
      case 'data': return 'Data';
      default: return fileType;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType) {
      case 'image': return Colors.blue;
      case 'audio': return Colors.purple;
      case 'video': return Colors.red;
      case 'document': return Colors.orange;
      case 'data': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'No Saved Files Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Use Gradio apps and download files to save them here for offline access.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Results Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'No files match your search criteria',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesGrid() {
    return RefreshIndicator(
      onRefresh: _loadSavedFiles,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredFiles.length,
        itemBuilder: (context, index) {
          final file = _filteredFiles[index];
          return _buildFileCard(file);
        },
      ),
    );
  }

  Widget _buildFileCard(SavedGeneratedFile file) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileViewerScreen(savedFile: file),
            ),
          ).then((_) => _loadSavedFiles());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildFilePreview(file),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        file.originalFileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Flexible(
                      child: Text(
                        file.spaceName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getFileTypeColor(file.fileType).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                file.fileTypeCategory,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _getFileTypeColor(file.fileType),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            file.formattedFileSize,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 1),

                    Flexible(
                      child: Text(
                        file.formattedTimestamp,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(SavedGeneratedFile file) {
    if (file.fileType == 'image' && file.fileExists) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.localFilePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFileIcon(file);
          },
        ),
      );
    }

    return _buildFileIcon(file);
  }

  Widget _buildFileIcon(SavedGeneratedFile file) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            file.fileTypeIcon,
            style: TextStyle(
              fontSize: 32,
              color: _getFileTypeColor(file.fileType),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            file.fileExtension.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'storage_info':
        _showStorageInfoDialog();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _showStorageInfoDialog() async {
    final storageInfo = await FileStorageService.getStorageInfo();
    final fileCount = await SavedFilesDatabase.getFilesCount();
    final fileCountsByType = await SavedFilesDatabase.getFileCountsByType();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total files: $fileCount'),
              const SizedBox(height: 8),
              Text(storageInfo),
              const SizedBox(height: 16),
              const Text('Files by type:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...fileCountsByType.entries.map((entry) =>
                Text('${_getFileTypeLabel(entry.key)}: ${entry.value}')
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Files'),
        content: const Text(
          'Are you sure you want to delete all saved files? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              await SavedFilesDatabase.clearAllFiles();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All files cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              _loadSavedFiles();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}