import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/huggingface_space.dart';
import '../models/space_type.dart';

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

  static Future<List<HuggingFaceSpace>> getUserCreatedSpaces(String username) async {
    try {
      // Fetch user's created spaces (most reliable)
      final response = await http.get(
        Uri.parse('$baseUrl?author=$username&sort=likes&direction=-1&limit=100&full=true'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final userSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();
        
        // Filter to only include Gradio spaces by the user
        final gradioSpaces = userSpaces.where((space) => 
          space.sdk?.toLowerCase() == 'gradio' && space.author.toLowerCase() == username.toLowerCase()
        ).toList();
        
        if (gradioSpaces.isEmpty) {
          throw Exception('No Gradio spaces found for user "$username".');
        }
        
        return gradioSpaces;
      } else {
        throw Exception('User "$username" not found or has no accessible spaces');
      }
    } catch (e) {
      if (e.toString().contains('No Gradio spaces found')) {
        rethrow;
      }
      throw Exception('Error fetching spaces: $e');
    }
  }

  static Future<List<HuggingFaceSpace>> getSpacesByType(String spaceTypeId) async {
    try {
      final spaceType = SpaceType.spaceTypes.firstWhere((type) => type.id == spaceTypeId);

      final response = await http.get(
        Uri.parse('$baseUrl?sort=likes&direction=-1&limit=1000&full=true'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        // Filter to only include Gradio spaces
        final gradioSpaces = allSpaces.where((space) =>
          space.sdk?.toLowerCase() == 'gradio'
        ).toList();

        // Filter to only include spaces updated in the last 12 months (more lenient)
        final now = DateTime.now();
        final twelveMonthsAgo = now.subtract(const Duration(days: 365));

        final recentSpaces = gradioSpaces.where((space) {
          if (space.lastModified == null) return true; // Include spaces without lastModified
          return space.lastModified!.isAfter(twelveMonthsAgo);
        }).toList();

        // Filter by space type
        final typedSpaces = recentSpaces.where((space) {
          final detectedType = SpaceType.getSpaceTypeForTags(
            space.tags,
            title: space.name,
            description: space.description,
          );
          return detectedType?.id == spaceTypeId;
        }).toList();

        // Sort by likes
        typedSpaces.sort((a, b) => b.likes.compareTo(a.likes));

        // Return top 100 spaces of this type
        return typedSpaces.take(100).toList();
      } else {
        throw Exception('Failed to load spaces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching spaces by type: $e');
    }
  }

  static Future<List<HuggingFaceSpace>> getUserLikedSpaces(String username, {String? accessToken}) async {
    try {
      print('Getting PUBLIC liked spaces for user: $username');

      // Try to get public likes without authentication first
      final response = await http.get(
        Uri.parse('https://huggingface.co/api/users/$username/likes'),
        headers: {'Accept': 'application/json'},
      );

      print('Public likes API response status: ${response.statusCode}');
      print('Public likes API response body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Filter to only include spaces (not models or datasets)
        final likedSpaces = data.where((item) {
          if (item['repo'] == null) return false;
          final repoType = item['repo']['type'];
          return repoType == 'space';
        }).toList();

        print('Found ${likedSpaces.length} liked spaces');

        // Get space names from liked spaces
        final spaceNames = likedSpaces
            .map((item) {
              final repo = item['repo'];
              if (repo == null) return null;
              return repo['name'] as String?;
            })
            .where((name) => name != null)
            .cast<String>()
            .take(50) // Limit to first 50 to avoid too many API calls
            .toList();

        print('Processing ${spaceNames.length} space names: ${spaceNames.take(5)}...');

        // Fetch all spaces from the spaces API and filter for the liked ones
        final allSpacesResponse = await http.get(
          Uri.parse('https://huggingface.co/api/spaces?sort=likes&direction=-1&limit=1000&full=true'),
          headers: {'Accept': 'application/json'},
        );

        final spaces = <HuggingFaceSpace>[];
        if (allSpacesResponse.statusCode == 200) {
          final List<dynamic> allSpacesData = json.decode(allSpacesResponse.body);
          final allSpaces = allSpacesData.map((json) => HuggingFaceSpace.fromJson(json)).toList();

          // Filter to only include liked spaces
          for (final spaceName in spaceNames) {
            try {
              final matchingSpace = allSpaces.firstWhere(
                (space) => space.id == spaceName,
                orElse: () => HuggingFaceSpace(
                  id: spaceName,
                  name: spaceName.split('/').last,
                  author: spaceName.split('/').first,
                  likes: 0,
                  url: 'https://${spaceName.replaceAll('/', '-')}.hf.space',
                  thumbnailUrl: 'https://huggingface.co/spaces/$spaceName/thumbnail.png',
                  tags: [],
                ),
              );
              spaces.add(matchingSpace);
            } catch (e) {
              // Skip spaces that can't be processed
              continue;
            }
          }
        }

        // Filter to only include Gradio spaces
        final gradioSpaces = spaces.where((space) =>
          space.sdk?.toLowerCase() == 'gradio'
        ).toList();

        // Sort by likes (most popular first)
        gradioSpaces.sort((a, b) => b.likes.compareTo(a.likes));

        print('Returning ${gradioSpaces.length} Gradio spaces from public likes');
        return gradioSpaces;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('Public likes API requires authentication or user has private likes');
        return [];
      } else if (response.statusCode == 404) {
        throw Exception('User "$username" not found.');
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching public liked spaces: $e');
      return [];
    }
  }

  /// Fallback method to get liked spaces using browser-like access
  static Future<List<HuggingFaceSpace>> _getBrowserBasedLikedSpaces(String username) async {
    try {
      print('Using browser-based fallback for liked spaces');

      // For now, we'll return a message that user needs to check manually
      // This could be enhanced to use web scraping or other methods

      // Alternative: Check user's public profile for any publicly visible liked spaces
      // But most liked spaces are private, so we'll return empty list with explanation

      print('Browser-based liked spaces access not yet implemented');
      print('Liked spaces are typically private and require authenticated session');

      return [];
    } catch (e) {
      print('Browser-based fallback failed: $e');
      return [];
    }
  }
}