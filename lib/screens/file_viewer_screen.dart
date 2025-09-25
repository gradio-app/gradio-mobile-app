import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:convert';
import '../models/saved_generated_file.dart';
import '../services/saved_files_database.dart';
import '../services/file_storage_service.dart';

class FileViewerScreen extends StatefulWidget {
  final SavedGeneratedFile savedFile;

  const FileViewerScreen({super.key, required this.savedFile});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool _isLoading = false;
  String? _description;

  @override
  void initState() {
    super.initState();
    _description = widget.savedFile.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.savedFile.originalFileName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDescription,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open_externally',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new),
                    SizedBox(width: 8),
                    Text('Open Externally'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // File info header
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.savedFile.fileTypeIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.savedFile.originalFileName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.savedFile.fileTypeCategory} • ${widget.savedFile.formattedFileSize}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'From ${widget.savedFile.spaceName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              widget.savedFile.formattedTimestamp,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_description != null && _description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // File content viewer
          Expanded(
            child: _buildFileContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    if (!widget.savedFile.fileExists) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'File not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'The file may have been moved or deleted',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    switch (widget.savedFile.fileType) {
      case 'image':
        return _buildImageViewer();
      case 'audio':
        return _buildAudioViewer();
      case 'video':
        return _buildVideoViewer();
      case 'document':
        return _buildDocumentViewer();
      case 'data':
        return _buildDataViewer();
      default:
        return _buildGenericFileViewer();
    }
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      child: Center(
        child: Image.file(
          File(widget.savedFile.localFilePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Unable to display image'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audiotrack,
            size: 64,
            color: Colors.blue[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Audio File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.savedFile.formattedFileSize} • ${widget.savedFile.fileExtension.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            size: 64,
            color: Colors.purple[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Video File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.savedFile.formattedFileSize} • ${widget.savedFile.fileExtension.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer() {
    if (widget.savedFile.fileExtension == 'txt' ||
        widget.savedFile.fileExtension == 'md') {
      return FutureBuilder<String>(
        future: File(widget.savedFile.localFilePath).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading file: ${snapshot.error}'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snapshot.data ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Document File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.savedFile.formattedFileSize} • ${widget.savedFile.fileExtension.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataViewer() {
    if (widget.savedFile.fileExtension == 'json') {
      return FutureBuilder<String>(
        future: File(widget.savedFile.localFilePath).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading file: ${snapshot.error}'),
                ],
              ),
            );
          }

          try {
            // Try to format JSON
            final jsonData = snapshot.data ?? '';
            final prettyJson = const JsonEncoder.withIndent('  ').convert(
              json.decode(jsonData),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                prettyJson,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          } catch (e) {
            // If JSON parsing fails, show raw content
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                snapshot.data ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          }
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_object,
            size: 64,
            color: Colors.teal[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Data File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.savedFile.formattedFileSize} • ${widget.savedFile.fileExtension.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFileViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.savedFile.fileTypeCategory,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.savedFile.formattedFileSize} • ${widget.savedFile.fileExtension.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
          ),
        ],
      ),
    );
  }

  void _editDescription() {
    final controller = TextEditingController(text: _description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a description for this file...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDescription = controller.text.trim();
              final success = await SavedFilesDatabase.updateFileDescription(
                widget.savedFile.id!,
                newDescription.isEmpty ? '' : newDescription,
              );

              if (success && mounted) {
                setState(() {
                  _description = newDescription.isEmpty ? null : newDescription;
                });
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareFile() async {
    try {
      final file = File(widget.savedFile.localFilePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Generated from ${widget.savedFile.spaceName}: ${widget.savedFile.originalFileName}',
          subject: 'Shared from Gradio Mobile App',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openExternally() async {
    try {
      final file = File(widget.savedFile.localFilePath);
      if (await file.exists()) {
        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done && mounted) {
          String message;
          switch (result.type) {
            case ResultType.noAppToOpen:
              message = 'No app available to open this file type';
              break;
            case ResultType.fileNotFound:
              message = 'File not found';
              break;
            case ResultType.permissionDenied:
              message = 'Permission denied to open file';
              break;
            default:
              message = 'Unable to open file: ${result.message}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'open_externally':
        _openExternally();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete "${widget.savedFile.originalFileName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              setState(() {
                _isLoading = true;
              });

              // Delete from database
              if (widget.savedFile.id != null) {
                await SavedFilesDatabase.deleteFile(widget.savedFile.id!);
              }

              // Delete physical file
              await FileStorageService.deleteFile(widget.savedFile);

              if (mounted) {
                Navigator.pop(context); // Go back to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${widget.savedFile.originalFileName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}