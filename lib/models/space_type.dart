import 'package:flutter/material.dart';

class SpaceType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> matchingTags;
  final String color;

  const SpaceType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.matchingTags,
    required this.color,
  });

  static const List<SpaceType> spaceTypes = [
    SpaceType(
      id: 'image-generation',
      name: 'Image Generation',
      description: 'Create images from text prompts',
      icon: Icons.image,
      matchingTags: ['image-generation', 'text-to-image', 'stable-diffusion', 'dalle', 'midjourney', 'flux', 'sdxl', 'diffusion', 'generate', 'create', 'art'],
      color: '#FF6B6B',
    ),
    SpaceType(
      id: 'video-generation',
      name: 'Video Generation',
      description: 'Create and edit videos with AI',
      icon: Icons.videocam,
      matchingTags: ['video-generation', 'video', 'animation', 'motion', 'film', 'clip', 'movie', 'render', 'edit'],
      color: '#9B59B6',
    ),
    SpaceType(
      id: 'text-generation',
      name: 'Text Generation',
      description: 'Generate text with language models',
      icon: Icons.text_fields,
      matchingTags: ['text-generation', 'language-model', 'gpt', 'llm', 'llama', 'mistral', 'completion', 'writing', 'generate'],
      color: '#3498DB',
    ),
    SpaceType(
      id: 'language-translation',
      name: 'Language Translation',
      description: 'Translate between languages',
      icon: Icons.translate,
      matchingTags: ['translation', 'translate', 'language', 'multilingual', 'translator', 'babel', 'nllb'],
      color: '#27AE60',
    ),
    SpaceType(
      id: 'speech-synthesis',
      name: 'Speech Synthesis',
      description: 'Text-to-speech and voice generation',
      icon: Icons.record_voice_over,
      matchingTags: ['tts', 'text-to-speech', 'speech-synthesis', 'voice', 'speak', 'vocoder', 'audio'],
      color: '#E74C3C',
    ),
    SpaceType(
      id: '3d-modeling',
      name: '3D Modeling',
      description: 'Generate and manipulate 3D models',
      icon: Icons.view_in_ar,
      matchingTags: ['3d', 'three-dimensional', 'mesh', 'model', 'shape', 'geometry', 'nerf', 'gaussian'],
      color: '#F39C12',
    ),
    SpaceType(
      id: 'object-detection',
      name: 'Object Detection',
      description: 'Detect and identify objects in images',
      icon: Icons.search,
      matchingTags: ['object-detection', 'detection', 'yolo', 'detect', 'identify', 'locate', 'bbox', 'vision'],
      color: '#16A085',
    ),
    SpaceType(
      id: 'text-analysis',
      name: 'Text Analysis',
      description: 'Analyze and understand text',
      icon: Icons.analytics,
      matchingTags: ['text-analysis', 'nlp', 'sentiment', 'classification', 'analysis', 'understand', 'extract'],
      color: '#8E44AD',
    ),
    SpaceType(
      id: 'image-editing',
      name: 'Image Editing',
      description: 'Edit and manipulate images',
      icon: Icons.edit,
      matchingTags: ['image-editing', 'edit', 'manipulation', 'inpainting', 'outpainting', 'remove', 'replace'],
      color: '#E67E22',
    ),
    SpaceType(
      id: 'code-generation',
      name: 'Code Generation',
      description: 'Generate and assist with code',
      icon: Icons.code,
      matchingTags: ['code-generation', 'coding', 'programming', 'code', 'github', 'copilot', 'codegen'],
      color: '#2C3E50',
    ),
    SpaceType(
      id: 'question-answering',
      name: 'Question Answering',
      description: 'Answer questions from text',
      icon: Icons.help_outline,
      matchingTags: ['question-answering', 'qa', 'answer', 'question', 'ask', 'retrieval', 'search'],
      color: '#34495E',
    ),
    SpaceType(
      id: 'data-visualization',
      name: 'Data Visualization',
      description: 'Visualize and explore data',
      icon: Icons.bar_chart,
      matchingTags: ['visualization', 'chart', 'graph', 'plot', 'data', 'dashboard', 'analytics'],
      color: '#1ABC9C',
    ),
    SpaceType(
      id: 'voice-cloning',
      name: 'Voice Cloning',
      description: 'Clone and synthesize voices',
      icon: Icons.mic,
      matchingTags: ['voice-cloning', 'voice', 'clone', 'synthesis', 'speaker', 'mimic', 'replica'],
      color: '#F1C40F',
    ),
    SpaceType(
      id: 'background-removal',
      name: 'Background Removal',
      description: 'Remove backgrounds from images',
      icon: Icons.layers,
      matchingTags: ['background-removal', 'background', 'remove', 'segment', 'mask', 'cutout', 'rembg'],
      color: '#95A5A6',
    ),
    SpaceType(
      id: 'image-upscaling',
      name: 'Image Upscaling',
      description: 'Enhance and upscale images',
      icon: Icons.zoom_in,
      matchingTags: ['upscaling', 'upscale', 'enhance', 'super-resolution', 'quality', 'resolution', 'esrgan'],
      color: '#D35400',
    ),
    SpaceType(
      id: 'ocr',
      name: 'OCR',
      description: 'Extract text from images',
      icon: Icons.text_snippet,
      matchingTags: ['ocr', 'optical-character-recognition', 'text-recognition', 'read', 'extract', 'tesseract'],
      color: '#7F8C8D',
    ),
    SpaceType(
      id: 'chatbots',
      name: 'Chatbots',
      description: 'Conversational AI assistants',
      icon: Icons.chat,
      matchingTags: ['chatbot', 'chat', 'conversation', 'assistant', 'bot', 'dialogue', 'conversational'],
      color: '#E91E63',
    ),
    SpaceType(
      id: 'music-generation',
      name: 'Music Generation',
      description: 'Generate and compose music',
      icon: Icons.music_note,
      matchingTags: ['music-generation', 'music', 'audio', 'compose', 'melody', 'song', 'sound'],
      color: '#9C27B0',
    ),
    SpaceType(
      id: 'style-transfer',
      name: 'Style Transfer',
      description: 'Transfer artistic styles to images',
      icon: Icons.palette,
      matchingTags: ['style-transfer', 'style', 'transfer', 'artistic', 'neural-style', 'art'],
      color: '#673AB7',
    ),
    SpaceType(
      id: 'face-recognition',
      name: 'Face Recognition',
      description: 'Recognize and analyze faces',
      icon: Icons.face,
      matchingTags: ['face-recognition', 'face', 'facial', 'recognition', 'identity', 'person', 'detect'],
      color: '#FF5722',
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