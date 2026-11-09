import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Live production backend URL (where admin prices are updated)
  static const String _productionApiUrl = 'http://localhost:5004/api';

  // Local backend URLs (port 5004)
  static const String _localApiUrlWeb = 'http://localhost:5004/api';
  static const String _localApiUrlAndroid = 'http://10.0.2.2:5004/api';

  /// Set to true only if testing against a locally running backend on port 5004.
  /// Defaults to false so the app seamlessly fetches live admin prices from the cloud backend.
  static const bool useLocalBackend = false;

  // API_URL can override the default when supplied at build time.
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_URL');

    if (customUrl.isNotEmpty) {
      return customUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    if (useLocalBackend) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return _localApiUrlAndroid;
      }
      return _localApiUrlWeb;
    }

    return _productionApiUrl;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _buildUri(String endpoint) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return Uri.parse('$baseUrl$normalizedEndpoint');
  }

  static Uri _buildProdFallbackUri(String endpoint) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return Uri.parse('$_productionApiUrl$normalizedEndpoint');
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final primaryUri = _buildUri(endpoint);

    try {
      final response = await http
          .get(primaryUri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return response;
      }
    } catch (e) {
      print('[ApiService] GET $primaryUri failed: $e');
    }

    // If primary was local or failed, automatically retry with live production
    if (!primaryUri.toString().contains('vercel.app')) {
      try {
        final fallbackUri = _buildProdFallbackUri(endpoint);
        print('[ApiService] Retrying GET with production: $fallbackUri');
        return await http
            .get(fallbackUri, headers: headers)
            .timeout(const Duration(seconds: 12));
      } catch (err) {
        print('[ApiService] Production fallback GET failed: $err');
      }
    }

    return http.Response(
      jsonEncode({'success': false, 'error': 'Network error'}),
      503,
    );
  }

  static Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final primaryUri = _buildUri(endpoint);
    final jsonBody = jsonEncode(body);

    try {
      final response = await http
          .post(primaryUri, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return response;
      }
    } catch (e) {
      print('[ApiService] POST $primaryUri failed: $e');
    }

    // If primary was local or failed, automatically retry with live production
    if (!primaryUri.toString().contains('vercel.app')) {
      try {
        final fallbackUri = _buildProdFallbackUri(endpoint);
        print('[ApiService] Retrying POST with production: $fallbackUri');
        return await http
            .post(fallbackUri, headers: headers, body: jsonBody)
            .timeout(const Duration(seconds: 12));
      } catch (err) {
        print('[ApiService] Production fallback POST failed: $err');
      }
    }

    return http.Response(
      jsonEncode({'success': false, 'error': 'Network error'}),
      503,
    );
  }

  static Future<http.Response> put(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final primaryUri = _buildUri(endpoint);
    final jsonBody = jsonEncode(body);

    try {
      final response = await http
          .put(primaryUri, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return response;
      }
    } catch (e) {
      print('[ApiService] PUT $primaryUri failed: $e');
    }

    if (!primaryUri.toString().contains('vercel.app')) {
      try {
        final fallbackUri = _buildProdFallbackUri(endpoint);
        return await http
            .put(fallbackUri, headers: headers, body: jsonBody)
            .timeout(const Duration(seconds: 12));
      } catch (err) {
        print('[ApiService] Production fallback PUT failed: $err');
      }
    }

    return http.Response(
      jsonEncode({'success': false, 'error': 'Network error'}),
      503,
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final primaryUri = _buildUri(endpoint);

    try {
      final response = await http
          .delete(primaryUri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return response;
      }
    } catch (e) {
      print('[ApiService] DELETE $primaryUri failed: $e');
    }

    if (!primaryUri.toString().contains('vercel.app')) {
      try {
        final fallbackUri = _buildProdFallbackUri(endpoint);
        return await http
            .delete(fallbackUri, headers: headers)
            .timeout(const Duration(seconds: 12));
      } catch (err) {
        print('[ApiService] Production fallback DELETE failed: $err');
      }
    }

    return http.Response(
      jsonEncode({'success': false, 'error': 'Network error'}),
      503,
    );
  }
}
