import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error - verifyToken: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/user/profile'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error - getUserProfile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateTypingCount(int charCount) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/typing/update'),
        headers: _getHeaders(token: token),
        body: json.encode({'charCount': charCount}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update typing count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error - updateTypingCount: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTypingStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/typing/stats'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get typing stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error - getTypingStats: $e');
      rethrow;
    }
  }

  static Future<void> deleteAccount() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/user/account'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error - deleteAccount: $e');
      rethrow;
    }
  }
}