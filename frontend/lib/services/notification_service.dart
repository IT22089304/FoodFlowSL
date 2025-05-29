import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api.dart' as app_api;

class NotificationService {
  // ✅ Get all notifications
  static Future<List<dynamic>> getNotifications() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to fetch notifications: ${response.body}");
      return [];
    }
  }

  // ✅ Create a new notification (with optional fields for donation link)
  static Future<bool> createNotification({
    required String userId,
    required String message,
    String type = 'info',
    String? targetDonationId,
    String? targetDonationTitle,
    String? targetDonationImage,
  }) async {
    final token = await AuthService.getToken();

    final Map<String, dynamic> body = {
      'user': userId,
      'message': message,
      'type': type,
    };

    if (targetDonationId != null) body['targetDonationId'] = targetDonationId;
    if (targetDonationTitle != null)
      body['targetDonationTitle'] = targetDonationTitle;
    if (targetDonationImage != null)
      body['targetDonationImage'] = targetDonationImage;

    final response = await http.post(
      Uri.parse('${app_api.Api.baseUrl}/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      print("✅ Notification created!");
      return true;
    } else {
      print("❌ Failed to create notification: ${response.body}");
      return false;
    }
  }

  // ✅ Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // ✅ Delete a specific notification
  static Future<bool> deleteNotification(String notificationId) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('${app_api.Api.baseUrl}/notifications/$notificationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
