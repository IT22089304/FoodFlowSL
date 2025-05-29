import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String baseUrl =
      'https://flask-backend-674619165214.asia-south1.run.app';
}

class AuthService {
  // ✅ Login User and Store Token & Role
  static Future<bool> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      return true;
    } else {
      print('❌ Login failed: ${response.body}');
      return false;
    }
  }

  // ✅ Register New User
  static Future<bool> registerUser(
    String name,
    String email,
    String password,
    String role,
    double lat,
    double lng,
  ) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'location': {'lat': lat, 'lng': lng},
        'profilePic': "", // Optional profile picture URL
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('❌ Registration failed: ${response.body}');
      return false;
    }
  }

  // ✅ Extract User ID from JWT Token
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload['sub'] ?? payload['_id'] ?? payload['user'];
    } catch (e) {
      print('❌ Error decoding token: $e');
      return null;
    }
  }

  // ✅ Update User Profile
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${Api.baseUrl}/api/auth/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ Profile update failed: ${response.body}');
      return false;
    }
  }

  // ✅ Logout User (Clear Stored Data)
  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // ✅ Retrieve Stored Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Save User Role Locally
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  // ✅ Get Stored User Role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ✅ Get Current User Profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Api.baseUrl}/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Failed to fetch profile: ${response.body}');
      return null;
    }
  }

  // ✅ Get User Details by User ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Api.baseUrl}/api/auth/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Failed to fetch user details: ${response.body}');
      return null;
    }
  }
}
