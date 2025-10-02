import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class HuggingFaceUser {
  final String username;
  final String? email;
  final String? profilePicture;
  final String? profileUrl;
  final bool isPro;

  HuggingFaceUser({
    required this.username,
    this.email,
    this.profilePicture,
    this.profileUrl,
    this.isPro = false,
  });

  factory HuggingFaceUser.fromJson(Map<String, dynamic> json) {
    return HuggingFaceUser(
      username: json['name'] ?? json['username'] ?? json['login'] ?? '',
      email: json['email'],
      profilePicture: json['picture'] ?? json['avatarUrl'],
      profileUrl: json['profile'],
      isPro: json['is_pro'] ?? json['isPro'] ?? false,
    );
  }
}

class HFOAuthService {
  static const String _clientId = 'a03476fc-08f9-4555-a5d8-de032815716f';
  static const String _redirectUri = 'com.example.gradiomobileapp://oauth';
  static const String _authorizationEndpoint = 'https://huggingface.co/oauth/authorize';
  static const String _tokenEndpoint = 'https://huggingface.co/oauth/token';
  static const String _userInfoEndpoint = 'https://huggingface.co/api/whoami';

  static const List<String> _scopes = ['openid', 'profile', 'read-repos'];

  static const FlutterAppAuth _appAuth = FlutterAppAuth();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _accessTokenKey = 'hf_access_token';
  static const String _refreshTokenKey = 'hf_refresh_token';
  static const String _userDataKey = 'hf_user_data';

  static String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static Future<bool> isAuthenticated() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    return accessToken != null && accessToken.isNotEmpty;
  }

  static Future<HuggingFaceUser?> getCachedUser() async {
    try {
      final userDataJson = await _secureStorage.read(key: _userDataKey);
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        return HuggingFaceUser.fromJson(userData);
      }
    } catch (e) {
      print('Error reading cached user data: $e');
    }
    return null;
  }

  static Future<HuggingFaceUser?> login() async {
    try {
      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
        scopes: _scopes,
      );

      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(request);

      if (result != null && result.accessToken != null) {
        print('OAuth success! Token type: ${result.tokenType}');
        print('Access token length: ${result.accessToken!.length}');
        print('Token expires in: ${result.accessTokenExpirationDateTime}');
        print('Scopes: ${result.scopes}');

        await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
        if (result.refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
        }

        final user = await _fetchUserInfo(result.accessToken!);
        if (user != null) {
          await _cacheUserData(user);
          return user;
        }
      } else {
        print('OAuth failed: No access token received');
      }
    } catch (e) {
      print('OAuth login error: $e');
      throw Exception('Login failed: $e');
    }
    return null;
  }

  static Future<HuggingFaceUser?> _fetchUserInfo(String accessToken) async {
    try {
      print('Access token received: ${accessToken.substring(0, 20)}...');

      var response = await http.get(
        Uri.parse('https://huggingface.co/oauth/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      print('UserInfo endpoint response status: ${response.statusCode}');
      print('UserInfo endpoint response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return HuggingFaceUser.fromJson(userData);
      }

      response = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      print('Whoami endpoint response status: ${response.statusCode}');
      print('Whoami endpoint response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return HuggingFaceUser.fromJson(userData);
      }

      response = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': accessToken,
          'Accept': 'application/json',
        },
      );

      print('Alternative auth response status: ${response.statusCode}');
      print('Alternative auth response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return HuggingFaceUser.fromJson(userData);
      }

      print('All user info attempts failed');
      throw Exception('Failed to fetch user information - all endpoints returned errors');
    } catch (e) {
      print('Error fetching user info: $e');
      throw Exception('Error fetching user information: $e');
    }
  }

  static Future<void> _cacheUserData(HuggingFaceUser user) async {
    final userDataJson = json.encode({
      'name': user.username,
      'email': user.email,
      'picture': user.profilePicture,
      'profile': user.profileUrl,
      'is_pro': user.isPro,
    });
    await _secureStorage.write(key: _userDataKey, value: userDataJson);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final TokenRequest request = TokenRequest(
        _clientId,
        _redirectUri,
        refreshToken: refreshToken,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
      );

      final TokenResponse? result = await _appAuth.token(request);

      if (result != null && result.accessToken != null) {
        await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
        if (result.refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
        }
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    return false;
  }

  static Future<HuggingFaceUser?> getCurrentUser() async {
    var user = await getCachedUser();
    if (user != null) return user;

    final accessToken = await getAccessToken();
    if (accessToken != null) {
      try {
        user = await _fetchUserInfo(accessToken);
        if (user != null) {
          await _cacheUserData(user);
          return user;
        }
      } catch (e) {
        final refreshed = await refreshToken();
        if (refreshed) {
          final newAccessToken = await getAccessToken();
          if (newAccessToken != null) {
            user = await _fetchUserInfo(newAccessToken);
            if (user != null) {
              await _cacheUserData(user);
              return user;
            }
          }
        }
      }
    }

    return null;
  }

  static Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  static Future<bool> validateSession() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}