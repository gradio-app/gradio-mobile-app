import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/huggingface_space.dart';

class HuggingFaceService {
  static const String baseUrl = 'https://huggingface.co/api/spaces';

  static Future<List<HuggingFaceSpace>> getTrendingSpaces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?sort=likes&direction=-1&limit=500&full=true'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();
        
        // Filter to only include Gradio spaces
        final gradioSpaces = allSpaces.where((space) => 
          space.sdk?.toLowerCase() == 'gradio'
        ).toList();
        
        // Filter to only include spaces updated in the last 2 months
        final now = DateTime.now();
        final twoMonthsAgo = now.subtract(const Duration(days: 60));
        
        final recentSpaces = gradioSpaces.where((space) {
          if (space.lastModified == null) return false;
          return space.lastModified!.isAfter(twoMonthsAgo);
        }).toList();
        
        // Sort by likes (already sorted from API, but ensure order)
        recentSpaces.sort((a, b) => b.likes.compareTo(a.likes));
        
        // Return top 20 trending spaces
        return recentSpaces.take(20).toList();
      } else {
        throw Exception('Failed to load spaces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching spaces: $e');
    }
  }

  static Future<List<HuggingFaceSpace>> searchSpaces(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?search=$query&sort=likes&direction=-1&limit=20&filter=gradio&full=true'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();
        
        // Filter to only include Gradio spaces
        final gradioSpaces = allSpaces.where((space) => 
          space.sdk?.toLowerCase() == 'gradio'
        ).toList();
        
        return gradioSpaces;
      } else {
        throw Exception('Failed to search spaces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching spaces: $e');
    }
  }
}