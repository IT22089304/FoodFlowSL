import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api.dart' as app_api;
import 'package:frontend/services/auth_service.dart';

class DonationService {
  // ✅ Create a new donation
  static Future<bool> createDonation({
    required String description,
    required String quantity,
    required DateTime expiresAt,
    required String imageUrl,
    required double lat,
    required double lng,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${app_api.Api.baseUrl}/donations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'description': description,
        'quantity': quantity,
        'expiresAt': expiresAt.toIso8601String(),
        'image': imageUrl,
        'location': {'lat': lat, 'lng': lng},
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("❌ Donation failed: ${response.body}");
      return false;
    }
  }

  // ✅ Fetch all available donations
  static Future<List<dynamic>> getAllAvailableDonations() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch available donations: ${response.body}");
      return [];
    }
  }

  // ✅ Fetch donor's own donations
  static Future<List<dynamic>> getMyDonations() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/my'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch my donations: ${response.body}");
      return [];
    }
  }

  // ✅ Update a donation
  static Future<bool> updateDonation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/donations/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Failed to update donation: ${response.body}");
      return false;
    }
  }

  // ✅ Delete a donation
  static Future<bool> deleteDonation(String id) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${app_api.Api.baseUrl}/donations/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // ✅ Claim a donation by creating an order
  static Future<bool> claimDonation(String donationId) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${app_api.Api.baseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'donationId': donationId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print("✅ Successfully claimed donation.");
      return true;
    } else {
      print("❌ Failed to claim donation: ${response.body}");
      return false;
    }
  }

  // ✅ Confirm delivery of a donation
  static Future<bool> confirmDonationStatus(String donationId) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${app_api.Api.baseUrl}/donations/confirm/$donationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Failed to confirm donation: ${response.body}");
      return false;
    }
  }

  // ✅ Rate a donation
  static Future<bool> rateDonation(String donationId, int rating) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${app_api.Api.baseUrl}/donations/$donationId/rate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rating': rating}),
    );

    if (response.statusCode == 409) {
      print("❌ Already rated this donation.");
      return false;
    }

    return response.statusCode == 200;
  }

  // ✅ Get the user's own rating for a donation
  static Future<int?> getMyRating(String donationId) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/$donationId/my-rating'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['rating'];
    }

    print("❌ Failed to fetch rating: ${response.body}");
    return null;
  }

  // ✅ Get all donations by a specific user
  static Future<List<dynamic>> getDonationsByUser(String donorId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/user/$donorId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch donor donations: ${response.body}");
      return [];
    }
  }

  // ✅ Get donor's public profile
  static Future<Map<String, dynamic>?> getDonorProfile(String donorId) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/donor/$donorId/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch donor profile: ${response.body}");
      return null;
    }
  }

  // ✅ Get completed donations by a donor
  static Future<List<dynamic>> getCompletedDonationsByDonor(
    String donorId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/donor/$donorId/completed'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch completed donations: ${response.body}");
      return [];
    }
  }

  // ✅ Get donation summary
  static Future<Map<String, dynamic>?> getDonationSummary(
    String donationId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${app_api.Api.baseUrl}/donations/$donationId/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch donation summary: ${response.body}");
      return null;
    }
  }
}
