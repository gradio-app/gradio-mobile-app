import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'hf_cache_';
  static const Duration defaultTTL = Duration(hours: 6);

  static Future<void> saveToCache(String key, dynamic data, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final expiryKey = '${cacheKey}_expiry';

      final ttlDuration = ttl ?? defaultTTL;
      final expiryTime = DateTime.now().add(ttlDuration).millisecondsSinceEpoch;

      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setInt(expiryKey, expiryTime);
    } catch (e) {
    }
  }

  static Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final expiryKey = '${cacheKey}_expiry';

      final expiryTime = prefs.getInt(expiryKey);
      if (expiryTime == null) return null;

      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        await clearCacheKey(key);
        return null;
      }

      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return null;

      return jsonDecode(cachedData);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCacheKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final expiryKey = '${cacheKey}_expiry';

      await prefs.remove(cacheKey);
      await prefs.remove(expiryKey);
    } catch (e) {
    }
  }

  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
    }
  }
}
