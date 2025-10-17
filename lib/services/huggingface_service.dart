import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/huggingface_space.dart';
import '../models/space_type.dart';
import 'cache_service.dart';

class HuggingFaceService {
  static const String baseUrl = 'https://huggingface.co/api/spaces';

  static String? _parseLinkHeader(String? linkHeader) {
    if (linkHeader == null || linkHeader.isEmpty) return null;

    final links = linkHeader.split(',');
    for (final link in links) {
      if (link.contains('rel="next"')) {
        final match = RegExp(r'<(.+?)>').firstMatch(link);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  static Future<List<HuggingFaceSpace>> getTrendingSpaces({bool useCache = true}) async {
    try {
      if (useCache) {
        final cachedData = await CacheService.getFromCache('trending_spaces');
        if (cachedData != null) {
          final List<dynamic> cachedList = cachedData as List;
          return cachedList.map((json) => HuggingFaceSpace.fromJson(json)).toList();
        }
      }

      final response = await http.get(
        Uri.parse('$baseUrl?sort=likes&direction=-1&limit=500&full=true&filter=gradio'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final gradioSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        final now = DateTime.now();
        final twoMonthsAgo = now.subtract(const Duration(days: 60));

        final recentSpaces = gradioSpaces.where((space) {
          if (space.lastModified == null) return false;
          return space.lastModified!.isAfter(twoMonthsAgo);
        }).toList();

        recentSpaces.sort((a, b) => b.likes.compareTo(a.likes));

        final result = recentSpaces.take(20).toList();

        if (useCache) {
          await CacheService.saveToCache(
            'trending_spaces',
            result.map((space) => space.toJson()).toList(),
          );
        }

        return result;
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
        return data.map((json) => HuggingFaceSpace.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search spaces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching spaces: $e');
    }
  }

  static Future<List<HuggingFaceSpace>> getUserCreatedSpaces(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?author=$username&sort=likes&direction=-1&limit=100&full=true&filter=gradio'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final gradioSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        // It's valid for a user to have no Gradio spaces, return empty list
        return gradioSpaces;
      } else if (response.statusCode == 404) {
        throw Exception('User "$username" not found');
      } else {
        throw Exception('Failed to fetch spaces for user "$username": ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching spaces: $e');
    }
  }

  static Future<List<HuggingFaceSpace>> getSpacesByType(String spaceTypeId, {bool useCache = true}) async {
    try {
      if (useCache) {
        final cachedData = await CacheService.getFromCache('spaces_by_type_$spaceTypeId');
        if (cachedData != null) {
          final List<dynamic> cachedList = cachedData as List;
          return cachedList.map((json) => HuggingFaceSpace.fromJson(json)).toList();
        }
      }

      final spaceType = SpaceType.spaceTypes.firstWhere((type) => type.id == spaceTypeId);

      final response = await http.get(
        Uri.parse('$baseUrl/semantic-search?category=${spaceType.semanticCategory}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final spaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        final result = spaces.where((space) => space.sdk?.toLowerCase() == 'gradio').toList();

        if (useCache) {
          await CacheService.saveToCache(
            'spaces_by_type_$spaceTypeId',
            result.map((space) => space.toJson()).toList(),
          );
        }

        return result;
      } else {
        throw Exception('Failed to load spaces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching spaces by type: $e');
    }
  }

  static Future<Map<String, dynamic>> getSpacesByTypeWithPagination(
    String spaceTypeId, {
    String? pageUrl,
    int limit = 100,
  }) async {
    try {
      final spaceType = SpaceType.spaceTypes.firstWhere((type) => type.id == spaceTypeId);

      String url;
      if (pageUrl != null) {
        url = pageUrl;
      } else {
        final primaryTag = spaceType.matchingTags.isNotEmpty ? spaceType.matchingTags.first : '';
        final filterParam = primaryTag.isNotEmpty ? '&filter=$primaryTag' : '';
        url = '$baseUrl?sort=likes&direction=-1&limit=$limit&full=true&filter=gradio$filterParam';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final gradioSpaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        final linkHeader = response.headers['link'];
        final nextPageUrl = _parseLinkHeader(linkHeader);

        final now = DateTime.now();
        final twelveMonthsAgo = now.subtract(const Duration(days: 365));

        final recentSpaces = gradioSpaces.where((space) {
          if (space.lastModified == null) return true;
          return space.lastModified!.isAfter(twelveMonthsAgo);
        }).toList();

        final typedSpaces = recentSpaces.where((space) {
          final detectedType = SpaceType.getSpaceTypeForTags(
            space.tags,
            title: space.name,
            description: space.description,
          );
          return detectedType?.id == spaceTypeId;
        }).toList();

        typedSpaces.sort((a, b) => b.likes.compareTo(a.likes));

        return {
          'spaces': typedSpaces,
          'nextPageUrl': nextPageUrl,
        };
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

      final response = await http.get(
        Uri.parse('https://huggingface.co/api/users/$username/likes'),
        headers: {'Accept': 'application/json'},
      );

      print('Public likes API response status: ${response.statusCode}');
      print('Public likes API response body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final likedSpaces = data.where((item) {
          if (item['repo'] == null) return false;
          final repoType = item['repo']['type'];
          return repoType == 'space';
        }).toList();

        print('Found ${likedSpaces.length} liked spaces');

        final spaceNamesWithTimestamp = likedSpaces
            .map((item) {
              final repo = item['repo'];
              if (repo == null) return null;
              return {
                'name': repo['name'] as String?,
                'likedAt': item['item']?['updatedAt'] as String?,
              };
            })
            .where((item) => item != null && item['name'] != null)
            .cast<Map<String, String?>>()
            .toList();

        print('Processing ${spaceNamesWithTimestamp.length} space names: ${spaceNamesWithTimestamp.take(5)}...');

        final allSpacesResponse = await http.get(
          Uri.parse('https://huggingface.co/api/spaces?sort=likes&direction=-1&limit=5000&full=true&filter=gradio'),
          headers: {'Accept': 'application/json'},
        );

        final spaces = <HuggingFaceSpace>[];
        if (allSpacesResponse.statusCode == 200) {
          final List<dynamic> allSpacesData = json.decode(allSpacesResponse.body);
          final allSpaces = allSpacesData.map((json) => HuggingFaceSpace.fromJson(json)).toList();

          for (final spaceData in spaceNamesWithTimestamp) {
            final spaceName = spaceData['name'];
            final likedAtStr = spaceData['likedAt'];

            if (spaceName == null) continue;

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

              final spaceWithLikedAt = HuggingFaceSpace(
                id: matchingSpace.id,
                name: matchingSpace.name,
                description: matchingSpace.description,
                author: matchingSpace.author,
                likes: matchingSpace.likes,
                sdk: matchingSpace.sdk,
                url: matchingSpace.url,
                thumbnailUrl: matchingSpace.thumbnailUrl,
                emoji: matchingSpace.emoji,
                status: matchingSpace.status,
                lastModified: matchingSpace.lastModified,
                tags: matchingSpace.tags,
                likedAt: likedAtStr != null ? DateTime.parse(likedAtStr) : null,
              );

              spaces.add(spaceWithLikedAt);
            } catch (e) {
              continue;
            }
          }
        }

        spaces.sort((a, b) {
          if (a.likedAt == null && b.likedAt == null) return 0;
          if (a.likedAt == null) return 1;
          if (b.likedAt == null) return -1;
          return b.likedAt!.compareTo(a.likedAt!);
        });

        print('Returning ${spaces.length} Gradio spaces from public likes');
        return spaces;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('Public likes API requires authentication or user has private likes');
        return [];
      } else if (response.statusCode == 404) {
        print('User "$username" has no public liked spaces or likes are private');
        return [];
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching public liked spaces: $e');
      return [];
    }
  }

  static Future<Map<String, int>> getPopularTags({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?sort=likes&direction=-1&limit=$limit&full=true&filter=gradio'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final spaces = data.map((json) => HuggingFaceSpace.fromJson(json)).toList();

        final Map<String, int> tagFrequency = {};
        for (final space in spaces) {
          for (final tag in space.tags) {
            tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
          }
        }

        final sortedTags = Map.fromEntries(
          tagFrequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
        );

        return sortedTags;
      } else {
        throw Exception('Failed to fetch tags: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching popular tags: $e');
    }
  }

  static Future<List<String>> getSuggestedCategories({int minFrequency = 10}) async {
    try {
      final tagFrequency = await getPopularTags();

      final existingTags = SpaceType.spaceTypes
          .expand((type) => type.matchingTags)
          .toSet();

      final suggestedTags = tagFrequency.entries
          .where((entry) => entry.value >= minFrequency && !existingTags.contains(entry.key))
          .map((entry) => entry.key)
          .take(20)
          .toList();

      return suggestedTags;
    } catch (e) {
      throw Exception('Error getting suggested categories: $e');
    }
  }
}