import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.100:8000'; // ✅ Your FastAPI base URL

  // --------------------------
  // ✅ Save Token Helper
  // --------------------------
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // --------------------------
  // ✅ Clear Token Helper
  // --------------------------
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // --------------------------
  // ✅ Check If Logged In
  // --------------------------
  static Future<bool> checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // --------------------------
  // ✅ SIGNUP
  // --------------------------
  static Future<String?> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        final token = resBody['access_token'];
        if (token != null) {
          await saveToken(token);
        }
        return null;
      } else {
        try {
          return jsonDecode(response.body)['detail'] ?? "Signup failed";
        } catch (_) {
          return "Signup failed: ${response.body}";
        }
      }
    } catch (e) {
      return "Signup error: $e";
    }
  }

  // --------------------------
  // ✅ LOGIN
  // --------------------------
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        final token = resBody['access_token'];
        if (token != null) {
          await saveToken(token);
        }
        return null;
      } else {
        try {
          final resBody = jsonDecode(response.body);
          return resBody['detail'] ?? "Login failed";
        } catch (_) {
          return "Login failed: ${response.body}";
        }
      }
    } catch (e) {
      return "Login error: $e";
    }
  }

  // --------------------------
  // ✅ Auth Header Helper
  // --------------------------
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --------------------------
  // ✅ Get Current Patient Details After Login
  // --------------------------
  static Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/patients/me'), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --------------------------
  // ✅ Optional debug/test route
  // --------------------------
  static Future<http.Response> getProfile() async {
    final headers = await getAuthHeaders();
    return await http.get(Uri.parse('$baseUrl/patients/me'), headers: headers);
  }

  // --------------------------
  // ✅ Submit Progress Feedback
  // --------------------------
  static Future<bool> submitProgress(String message) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/progress'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Progress submission failed: ${response.statusCode} → ${response.body}');
        return false;
      }
    } catch (e) {
      print('Progress submission error: $e');
      return false;
    }
  }

  // --------------------------
  // ✅ Get All Progress Entries
  // --------------------------
  static Future<List<dynamic>?> getProgressEntries() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/progress'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
