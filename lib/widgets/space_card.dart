import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/huggingface_space.dart';

class SpaceCard extends StatelessWidget {
  final HuggingFaceSpace space;
  final VoidCallback onTap;

  const SpaceCard({super.key, required this.space, required this.onTap});

  Color _deriveBaseColor(String seed) {
    final hash = seed.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor();
  }

  String _formatLastModified(DateTime? lastModified) {
    if (lastModified == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  static final Map<String, String?> _avatarUrlCache = {};

  Future<String?> _getAvatarUrl(String username) async {
    if (_avatarUrlCache.containsKey(username)) return _avatarUrlCache[username];
    try {
      final resp = await http.get(
        Uri.parse('https://huggingface.co/api/users/$username/avatar'),
        headers: {'Accept': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final url = data['avatarUrl'] as String?;
        _avatarUrlCache[username] = url;
        return url;
      }
    } catch (_) {}
    _avatarUrlCache[username] = null;
    return null;
  }

  Widget _buildAuthor(BuildContext context, Color base) {
    final initials = space.author.isNotEmpty ? space.author[0].toUpperCase() : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<String?>(
          future: _getAvatarUrl(space.author),
          builder: (context, snapshot) {
            final avatarUrl = snapshot.data;
            if (avatarUrl == null || snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: 9,
                backgroundColor: base.withOpacity(0.25),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
              );
            }
            return ClipOval(
              child: Image.network(
                avatarUrl,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return CircleAvatar(
                    radius: 9,
                    backgroundColor: base.withOpacity(0.25),
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          space.author,
          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = _deriveBaseColor(space.id);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withOpacity(0.35),
        base.withOpacity(0.18),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          border: Border.all(color: base.withOpacity(0.22), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (space.emoji != null) ...[
                        Text(space.emoji!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          space.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.1,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildAuthor(context, base),
                  if (space.description != null && space.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      space.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.65)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, size: 12, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              space.status ?? 'Running',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (space.lastModified != null)
                        Text(
                          _formatLastModified(space.lastModified),
                          style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.5)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${space.likes}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


