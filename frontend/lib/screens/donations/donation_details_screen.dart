import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';
import '../../services/notification_service.dart';
import 'donor_profile_screen.dart';
import '../donations/my_claimed_donations_screen.dart';

class DonationDetailsScreen extends StatefulWidget {
  final String donationId;

  const DonationDetailsScreen({super.key, required this.donationId});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  Map<String, dynamic>? donation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDonationDetails();
  }

  Future<void> fetchDonationDetails() async {
    final data = await DonationService.getDonationSummary(widget.donationId);
    print("🖼️ Image URL: ${data?['image']}");
    setState(() {
      donation = data;
      isLoading = false;
    });
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return "N/A";
    final dateTime = DateTime.parse(isoDate);
    return DateFormat.yMMMMd().add_jm().format(dateTime);
  }

  Future<void> _claimDonation() async {
    if (donation == null) return;

    final success = await DonationService.claimDonation(donation!['_id']);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation claimed successfully")),
      );

      final donorId = donation!['donorId'];
      final title = donation!['description'] ?? 'your donation';

      if (donorId != null) {
        await NotificationService.createNotification(
          userId: donorId,
          message: "Your donation '$title' has been claimed by a receiver.",
          type: 'donation',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyClaimedDonationsScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to claim donation")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : donation == null
              ? const Center(child: Text("Donation not found"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        donation!['image'],
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 📦 Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation!['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoRow("Quantity", donation!['quantity']),
                          _infoRow(
                            "Created At",
                            formatDate(donation!['createdAt']),
                          ),
                          _infoRow(
                            "Expires At",
                            formatDate(donation!['expiresAt']),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ Conditional claim button or message
                    if (donation!['status'] == 'pending') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _claimDonation,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Claim Donation"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Text(
                          "Donation is not available",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 👤 Donor profile
                    if (donation!['donorId'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DonorProfileScreen(
                                      donorId: donation!['donorId'],
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person),
                          label: const Text("View Donor Profile"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
