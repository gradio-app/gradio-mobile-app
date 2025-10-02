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
      matchingTags: ['image-generation', 'text-to-image', 'stable-diffusion', 'dalle', 'midjourney', 'flux', 'sdxl', 'diffusion', 'generate', 'create', 'art'],
      color: '#FF6B6B',
      semanticCategory: 'image-generation',
    ),
    SpaceType(
      id: 'video-generation',
      name: 'Video Generation',
      description: 'Create and edit videos with AI',
      icon: Icons.videocam,
      matchingTags: ['video-generation', 'video', 'animation', 'motion', 'film', 'clip', 'movie', 'render', 'edit'],
      color: '#9B59B6',
      semanticCategory: 'video-generation',
    ),
    SpaceType(
      id: 'text-generation',
      name: 'Text Generation',
      description: 'Generate text with language models',
      icon: Icons.text_fields,
      matchingTags: ['text-generation', 'language-model', 'gpt', 'llm', 'llama', 'mistral', 'completion', 'writing', 'generate'],
      color: '#3498DB',
      semanticCategory: 'text-generation',
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
      semanticCategory: 'audio',
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
    SpaceType(
      id: 'audio-processing',
      name: 'Audio Processing',
      description: 'Process and manipulate audio',
      icon: Icons.audio_file,
      matchingTags: ['audio', 'audio-processing', 'sound', 'noise-reduction', 'audio-enhancement', 'denoising', 'separation'],
      color: '#00BCD4',
    ),
    SpaceType(
      id: 'image-classification',
      name: 'Image Classification',
      description: 'Classify and categorize images',
      icon: Icons.category,
      matchingTags: ['image-classification', 'classification', 'categorize', 'classify', 'label', 'recognition', 'vision'],
      color: '#4CAF50',
    ),
    SpaceType(
      id: 'summarization',
      name: 'Summarization',
      description: 'Summarize text and documents',
      icon: Icons.summarize,
      matchingTags: ['summarization', 'summary', 'summarize', 'abstract', 'condense', 'brief', 'tldr'],
      color: '#FF9800',
    ),
    SpaceType(
      id: 'speech-recognition',
      name: 'Speech Recognition',
      description: 'Convert speech to text',
      icon: Icons.keyboard_voice,
      matchingTags: ['speech-recognition', 'asr', 'automatic-speech-recognition', 'speech-to-text', 'transcribe', 'whisper', 'voice'],
      color: '#03A9F4',
    ),
    SpaceType(
      id: 'video-editing',
      name: 'Video Editing',
      description: 'Edit and enhance videos',
      icon: Icons.movie_edit,
      matchingTags: ['video-editing', 'video', 'edit', 'cut', 'trim', 'effects', 'processing'],
      color: '#673AB7',
    ),
    SpaceType(
      id: 'depth-estimation',
      name: 'Depth Estimation',
      description: 'Estimate depth from images',
      icon: Icons.layers_outlined,
      matchingTags: ['depth-estimation', 'depth', 'stereo', '3d-reconstruction', 'disparity', 'depth-map'],
      color: '#607D8B',
    ),
    SpaceType(
      id: 'pose-estimation',
      name: 'Pose Estimation',
      description: 'Detect human poses and body keypoints',
      icon: Icons.accessibility_new,
      matchingTags: ['pose-estimation', 'pose', 'keypoint', 'skeleton', 'body', 'human', 'posture'],
      color: '#009688',
    ),
    SpaceType(
      id: 'segmentation',
      name: 'Image Segmentation',
      description: 'Segment and mask parts of images',
      icon: Icons.auto_awesome_mosaic,
      matchingTags: ['segmentation', 'semantic-segmentation', 'instance-segmentation', 'segment', 'mask', 'partition'],
      color: '#795548',
    ),
    SpaceType(
      id: 'image-to-text',
      name: 'Image to Text',
      description: 'Generate descriptions from images',
      icon: Icons.image_search,
      matchingTags: ['image-to-text', 'image-captioning', 'caption', 'describe', 'vision-language', 'vqa', 'blip'],
      color: '#FF4081',
    ),
    SpaceType(
      id: 'text-to-3d',
      name: 'Text to 3D',
      description: 'Generate 3D models from text',
      icon: Icons.threed_rotation,
      matchingTags: ['text-to-3d', '3d-generation', '3d', 'shape', 'mesh-generation', 'shap-e', 'point-e'],
      color: '#CDDC39',
    ),
    SpaceType(
      id: 'image-to-video',
      name: 'Image to Video',
      description: 'Animate images into videos',
      icon: Icons.play_circle_outline,
      matchingTags: ['image-to-video', 'animate', 'animation', 'motion', 'video-generation', 'animatediff'],
      color: '#FFC107',
    ),
    SpaceType(
      id: 'document-qa',
      name: 'Document QA',
      description: 'Answer questions about documents',
      icon: Icons.description,
      matchingTags: ['document-qa', 'document', 'pdf', 'question-answering', 'rag', 'retrieval', 'donut'],
      color: '#5C6BC0',
    ),
    SpaceType(
      id: 'gaming',
      name: 'Gaming & RL',
      description: 'Game playing and reinforcement learning',
      icon: Icons.sports_esports,
      matchingTags: ['gaming', 'game', 'reinforcement-learning', 'rl', 'agent', 'play', 'atari', 'chess'],
      color: '#EC407A',
    ),
    SpaceType(
      id: 'restoration',
      name: 'Image Restoration',
      description: 'Restore and repair damaged images',
      icon: Icons.auto_fix_high,
      matchingTags: ['restoration', 'restore', 'repair', 'colorization', 'old-photo', 'enhance', 'deblur'],
      color: '#AB47BC',
    ),
    SpaceType(
      id: 'motion-capture',
      name: 'Motion Capture',
      description: 'Capture and analyze motion',
      icon: Icons.directions_run,
      matchingTags: ['motion-capture', 'motion', 'mocap', 'tracking', 'movement', 'animation'],
      color: '#26A69A',
    ),
    SpaceType(
      id: 'avatar-generation',
      name: 'Avatar Generation',
      description: 'Generate and customize avatars',
      icon: Icons.person_outline,
      matchingTags: ['avatar', 'avatar-generation', 'character', 'profile', 'portrait', 'face-generation'],
      color: '#EF5350',
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