import 'package:flutter/material.dart';

class SpaceType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> matchingTags;
  final String color;
  final String? semanticCategory;

  const SpaceType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.matchingTags,
    required this.color,
    this.semanticCategory,
  });

  static const List<SpaceType> spaceTypes = [
    SpaceType(
      id: 'image-generation',
      name: 'Image Generation',
      description: 'Create images from text prompts',
      icon: Icons.image,
      matchingTags: [],
      color: '#FF6B6B',
      semanticCategory: 'image-generation',
    ),
    SpaceType(
      id: 'video-generation',
      name: 'Video Generation',
      description: 'Create and edit videos with AI',
      icon: Icons.videocam,
      matchingTags: [],
      color: '#9B59B6',
      semanticCategory: 'video-generation',
    ),
    SpaceType(
      id: 'text-generation',
      name: 'Text Generation',
      description: 'Generate text with language models',
      icon: Icons.text_fields,
      matchingTags: [],
      color: '#3498DB',
      semanticCategory: 'text-generation',
    ),
    SpaceType(
      id: 'language-translation',
      name: 'Language Translation',
      description: 'Translate between languages',
      icon: Icons.translate,
      matchingTags: [],
      color: '#27AE60',
      semanticCategory: 'language-translation',
    ),
    SpaceType(
      id: 'speech-synthesis',
      name: 'Speech Synthesis',
      description: 'Text-to-speech and voice generation',
      icon: Icons.record_voice_over,
      matchingTags: [],
      color: '#E74C3C',
      semanticCategory: 'speech-synthesis',
    ),
    SpaceType(
      id: '3d-modeling',
      name: '3D Modeling',
      description: 'Generate and manipulate 3D models',
      icon: Icons.view_in_ar,
      matchingTags: [],
      color: '#F39C12',
      semanticCategory: '3d-modeling',
    ),
    SpaceType(
      id: 'object-detection',
      name: 'Object Detection',
      description: 'Detect and identify objects in images',
      icon: Icons.search,
      matchingTags: [],
      color: '#16A085',
      semanticCategory: 'object-detection',
    ),
    SpaceType(
      id: 'text-analysis',
      name: 'Text Analysis',
      description: 'Analyze and understand text',
      icon: Icons.analytics,
      matchingTags: [],
      color: '#8E44AD',
      semanticCategory: 'text-analysis',
    ),
    SpaceType(
      id: 'image-editing',
      name: 'Image Editing',
      description: 'Edit and manipulate images',
      icon: Icons.edit,
      matchingTags: [],
      color: '#E67E22',
      semanticCategory: 'image-editing',
    ),
    SpaceType(
      id: 'code-generation',
      name: 'Code Generation',
      description: 'Generate and assist with code',
      icon: Icons.code,
      matchingTags: [],
      color: '#2C3E50',
      semanticCategory: 'code-generation',
    ),
    SpaceType(
      id: 'question-answering',
      name: 'Question Answering',
      description: 'Answer questions from text',
      icon: Icons.help_outline,
      matchingTags: [],
      color: '#34495E',
      semanticCategory: 'question-answering',
    ),
    SpaceType(
      id: 'data-visualization',
      name: 'Data Visualization',
      description: 'Visualize and explore data',
      icon: Icons.bar_chart,
      matchingTags: [],
      color: '#1ABC9C',
      semanticCategory: 'data-visualization',
    ),
    SpaceType(
      id: 'voice-cloning',
      name: 'Voice Cloning',
      description: 'Clone and synthesize voices',
      icon: Icons.mic,
      matchingTags: [],
      color: '#F1C40F',
      semanticCategory: 'voice-cloning',
    ),
    SpaceType(
      id: 'background-removal',
      name: 'Background Removal',
      description: 'Remove backgrounds from images',
      icon: Icons.layers,
      matchingTags: [],
      color: '#95A5A6',
      semanticCategory: 'background-removal',
    ),
    SpaceType(
      id: 'image-upscaling',
      name: 'Image Upscaling',
      description: 'Enhance and upscale images',
      icon: Icons.zoom_in,
      matchingTags: [],
      color: '#D35400',
      semanticCategory: 'image-upscaling',
    ),
    SpaceType(
      id: 'ocr',
      name: 'OCR',
      description: 'Extract text from images',
      icon: Icons.text_snippet,
      matchingTags: [],
      color: '#7F8C8D',
      semanticCategory: 'ocr',
    ),
    SpaceType(
      id: 'chatbots',
      name: 'Chatbots',
      description: 'Conversational AI assistants',
      icon: Icons.chat,
      matchingTags: [],
      color: '#E91E63',
      semanticCategory: 'chatbots',
    ),
    SpaceType(
      id: 'music-generation',
      name: 'Music Generation',
      description: 'Generate and compose music',
      icon: Icons.music_note,
      matchingTags: [],
      color: '#9C27B0',
      semanticCategory: 'music-generation',
    ),
    SpaceType(
      id: 'style-transfer',
      name: 'Style Transfer',
      description: 'Transfer artistic styles to images',
      icon: Icons.palette,
      matchingTags: [],
      color: '#673AB7',
      semanticCategory: 'style-transfer',
    ),
    SpaceType(
      id: 'face-recognition',
      name: 'Face Recognition',
      description: 'Recognize and analyze faces',
      icon: Icons.face,
      matchingTags: [],
      color: '#FF5722',
      semanticCategory: 'face-recognition',
    ),
    SpaceType(
      id: 'audio-processing',
      name: 'Audio Processing',
      description: 'Process and manipulate audio',
      icon: Icons.audio_file,
      matchingTags: [],
      color: '#00BCD4',
      semanticCategory: 'music-generation',
    ),
    SpaceType(
      id: 'image-classification',
      name: 'Image Classification',
      description: 'Classify and categorize images',
      icon: Icons.category,
      matchingTags: [],
      color: '#4CAF50',
      semanticCategory: 'image',
    ),
    SpaceType(
      id: 'summarization',
      name: 'Summarization',
      description: 'Summarize text and documents',
      icon: Icons.summarize,
      matchingTags: [],
      color: '#FF9800',
      semanticCategory: 'text-summarization',
    ),
    SpaceType(
      id: 'speech-recognition',
      name: 'Speech Recognition',
      description: 'Convert speech to text',
      icon: Icons.keyboard_voice,
      matchingTags: [],
      color: '#03A9F4',
      semanticCategory: 'speech-synthesis',
    ),
    SpaceType(
      id: 'video-editing',
      name: 'Video Editing',
      description: 'Edit and enhance videos',
      icon: Icons.movie_edit,
      matchingTags: [],
      color: '#673AB7',
      semanticCategory: 'video-generation',
    ),
    SpaceType(
      id: 'depth-estimation',
      name: 'Depth Estimation',
      description: 'Estimate depth from images',
      icon: Icons.layers_outlined,
      matchingTags: [],
      color: '#607D8B',
      semanticCategory: 'image',
    ),
    SpaceType(
      id: 'pose-estimation',
      name: 'Pose Estimation',
      description: 'Detect human poses and body keypoints',
      icon: Icons.accessibility_new,
      matchingTags: [],
      color: '#009688',
      semanticCategory: 'pose-estimation',
    ),
    SpaceType(
      id: 'segmentation',
      name: 'Image Segmentation',
      description: 'Segment and mask parts of images',
      icon: Icons.auto_awesome_mosaic,
      matchingTags: [],
      color: '#795548',
      semanticCategory: 'image',
    ),
    SpaceType(
      id: 'image-to-text',
      name: 'Image to Text',
      description: 'Generate descriptions from images',
      icon: Icons.image_search,
      matchingTags: [],
      color: '#FF4081',
      semanticCategory: 'image-captioning',
    ),
    SpaceType(
      id: 'text-to-3d',
      name: 'Text to 3D',
      description: 'Generate 3D models from text',
      icon: Icons.threed_rotation,
      matchingTags: [],
      color: '#CDDC39',
      semanticCategory: '3d-modeling',
    ),
    SpaceType(
      id: 'image-to-video',
      name: 'Image to Video',
      description: 'Animate images into videos',
      icon: Icons.play_circle_outline,
      matchingTags: [],
      color: '#FFC107',
      semanticCategory: 'video-generation',
    ),
    SpaceType(
      id: 'document-qa',
      name: 'Document QA',
      description: 'Answer questions about documents',
      icon: Icons.description,
      matchingTags: [],
      color: '#5C6BC0',
      semanticCategory: 'document-analysis',
    ),
    SpaceType(
      id: 'gaming',
      name: 'Gaming & RL',
      description: 'Game playing and reinforcement learning',
      icon: Icons.sports_esports,
      matchingTags: [],
      color: '#EC407A',
      semanticCategory: 'game-ai',
    ),
    SpaceType(
      id: 'restoration',
      name: 'Image Restoration',
      description: 'Restore and repair damaged images',
      icon: Icons.auto_fix_high,
      matchingTags: [],
      color: '#AB47BC',
      semanticCategory: 'image',
    ),
    SpaceType(
      id: 'motion-capture',
      name: 'Motion Capture',
      description: 'Capture and analyze motion',
      icon: Icons.directions_run,
      matchingTags: [],
      color: '#26A69A',
      semanticCategory: 'character-animation',
    ),
    SpaceType(
      id: 'avatar-generation',
      name: 'Avatar Generation',
      description: 'Generate and customize avatars',
      icon: Icons.person_outline,
      matchingTags: [],
      color: '#EF5350',
      semanticCategory: 'character-animation',
    ),
  ];

  static SpaceType? getSpaceTypeForTags(List<String> tags, {String? title, String? description}) {
    // Combine all text for broader matching
    final allText = [
      ...tags,
      if (title != null) title,
      if (description != null) description,
    ].join(' ').toLowerCase();

    // Score each space type based on matches
    Map<SpaceType, int> scores = {};

    for (final spaceType in spaceTypes) {
      int score = 0;

      // Check tag matches (higher weight)
      for (final tag in tags) {
        for (final matchingTag in spaceType.matchingTags) {
          if (tag.toLowerCase().contains(matchingTag.toLowerCase()) ||
              matchingTag.toLowerCase().contains(tag.toLowerCase())) {
            score += 3;
          }
        }
      }

      // Check title and description matches (lower weight)
      for (final matchingTag in spaceType.matchingTags) {
        if (allText.contains(matchingTag.toLowerCase())) {
          score += 1;
        }
      }

      if (score > 0) {
        scores[spaceType] = score;
      }
    }

    // Return the space type with the highest score
    if (scores.isEmpty) return null;

    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.first.key;
  }
}