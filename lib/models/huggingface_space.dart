class HuggingFaceSpace {
  final String id;
  final String name;
  final String? description;
  final String author;
  final int likes;
  final String? sdk;
  final String url;
  final String thumbnailUrl;
  final String? emoji;
  final String? status;
  final DateTime? lastModified;
  final List<String> tags;
  final DateTime? likedAt;
  final String? aiCategory;
  final String? aiShortDescription;
  final double? semanticRelevancyScore;
  final double? trendingScore;

  HuggingFaceSpace({
    required this.id,
    required this.name,
    this.description,
    required this.author,
    required this.likes,
    this.sdk,
    required this.url,
    required this.thumbnailUrl,
    this.emoji,
    this.status,
    this.lastModified,
    this.tags = const [],
    this.likedAt,
    this.aiCategory,
    this.aiShortDescription,
    this.semanticRelevancyScore,
    this.trendingScore,
  });

  factory HuggingFaceSpace.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    final parts = id.split('/');
    final author = parts.isNotEmpty ? parts[0] : '';
    final name = parts.length > 1 ? parts[1] : id;

    final subdomain = id.replaceAll('/', '-').toLowerCase();
    final url = 'https://$subdomain.hf.space';
    final thumbnailUrl = 'https://huggingface.co/spaces/$id/thumbnail.png';

    DateTime? lastModified;
    if (json['lastModified'] != null) {
      try {
        lastModified = DateTime.parse(json['lastModified']);
      } catch (e) {
        lastModified = null;
      }
    }
    
    // Parse runtime status from API
    String? runtimeStatus;
    if (json['runtime'] != null && json['runtime']['stage'] != null) {
      final stage = json['runtime']['stage'].toString().toLowerCase();
      switch (stage) {
        case 'running':
        case 'running_building':
          runtimeStatus = 'Running';
          break;
        case 'stopped':
        case 'paused':
          runtimeStatus = 'Stopped';
          break;
        case 'building':
        case 'app_starting':
          runtimeStatus = 'Building';
          break;
        case 'runtime_error':
        case 'build_error':
          runtimeStatus = 'Error';
          break;
        default:
          runtimeStatus = stage.replaceAll('_', ' ');
      }
    }

    return HuggingFaceSpace(
      id: id,
      name: name,
      description: json['cardData']?['title'] ?? json['title'] ?? json['description'],
      author: author,
      likes: json['likes'] ?? 0,
      sdk: json['sdk'],
      url: url,
      thumbnailUrl: thumbnailUrl,
      emoji: json['cardData']?['emoji'] ?? json['emoji'],
      status: runtimeStatus,
      lastModified: lastModified,
      tags: List<String>.from(json['tags'] ?? []),
      likedAt: json['likedAt'] != null ? DateTime.parse(json['likedAt']) : null,
      aiCategory: json['ai_category'],
      aiShortDescription: json['ai_short_description'],
      semanticRelevancyScore: json['semanticRelevancyScore'] != null ? (json['semanticRelevancyScore'] as num).toDouble() : null,
      trendingScore: json['trendingScore'] != null ? (json['trendingScore'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'likes': likes,
      'sdk': sdk,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'cardData': {
        'emoji': emoji,
        'title': description,
      },
      'runtime': status != null ? {
        'stage': status,
      } : null,
      'lastModified': lastModified?.toIso8601String(),
      'tags': tags,
      'likedAt': likedAt?.toIso8601String(),
      'ai_category': aiCategory,
      'ai_short_description': aiShortDescription,
      'semanticRelevancyScore': semanticRelevancyScore,
      'trendingScore': trendingScore,
    };
  }
}