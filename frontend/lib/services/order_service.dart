import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api.dart' as app_api;

class OrderService {
  static Future<List<dynamic>> getMyOrders() async {
    final token = await AuthService.getToken();
    print("🔐 Token: $token");

    final url = '${app_api.Api.baseUrl}/orders/my';
    print("🌍 Calling: $url");

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("📥 Response code: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch claimed donations");
      return [];
    }
  }

  static Future<bool> confirmOrder(String orderId) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/orders/$orderId/status'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({"status": "confirmed"}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> claimDelivery(String donationId) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/orders/volunteer/claim/$donationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getMyAvailableOrders() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse(
        '${app_api.Api.baseUrl}/orders/available',
      ), // backend needs this
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to fetch available orders: ${response.body}");
      return [];
    }
  }

  static Future<String?> getCurrentUserId() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['_id'];
    }

    return null;
  }

  static Future<List<dynamic>> getMyAvailableAndAssignedOrders() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse(
        '${app_api.Api.baseUrl}/orders',
      ), // You can use a general endpoint or create a custom one
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to fetch orders: ${response.body}");
      return [];
    }
  }

  static Future<bool> confirmDelivery(String orderId) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/orders/$orderId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'delivered'}),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getOrderLocations(String orderId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/orders/locations/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch order locations: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOrderUsers(String orderId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${Api.baseUrl}/api/orders/users/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch order users: ${response.body}");
      return null;
    }
  }

  static Future<List<dynamic>> getMyAssignedOrders() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse(
        '${app_api.Api.baseUrl}/orders/assigned',
      ), // backend route you'll set up
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to fetch assigned orders: ${response.body}");
      return [];
    }
  }
}
