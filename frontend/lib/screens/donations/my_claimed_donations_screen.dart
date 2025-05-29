import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';
import '../../services/donation_service.dart';

class MyClaimedDonationsScreen extends StatefulWidget {
  const MyClaimedDonationsScreen({super.key});

  @override
  State<MyClaimedDonationsScreen> createState() =>
      _MyClaimedDonationsScreenState();
}

class _MyClaimedDonationsScreenState extends State<MyClaimedDonationsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> claimed = [];
  bool isLoading = true;
  late TabController _tabController;
  Map<String, int?> userRatings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchClaimedDonations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchClaimedDonations() async {
    final data = await OrderService.getMyOrders();
    setState(() {
      claimed = data;
      isLoading = false;
    });

    for (var order in data) {
      if (order['status'] == 'delivered') {
        final donationId = order['donationId']['_id'];
        final rating = await DonationService.getMyRating(donationId);
        setState(() {
          userRatings[donationId] = rating;
        });
      }
    }
  }

  Future<void> confirmReceived(String orderId) async {
    final success = await OrderService.confirmOrder(orderId);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Donation confirmed")));

      final order = claimed.firstWhere((o) => o['_id'] == orderId);
      final donation = order['donationId'] ?? {};
      final donorId = donation['donorId'];
      final volunteerId = order['volunteerId'];
      final donationTitle = donation['description'] ?? 'your donation';
      final donationImage = donation['image'];

      if (donorId != null) {
        await NotificationService.createNotification(
          userId: donorId,
          message:
              "Your donation '$donationTitle' has been confirmed by the receiver.",
          type: "donation",
          targetDonationId: donation['_id'],
          targetDonationTitle: donationTitle,
          targetDonationImage: donationImage,
        );
      }

      if (volunteerId != null) {
        await NotificationService.createNotification(
          userId: volunteerId,
          message: "Receiver has confirmed delivery of '$donationTitle'.",
          type: "donation",
          targetDonationId: donation['_id'],
          targetDonationTitle: donationTitle,
          targetDonationImage: donationImage,
        );
      }

      fetchClaimedDonations();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Confirmation failed")));
    }
  }

  Widget _buildList(String statusFilter) {
    final filtered = claimed.where((o) => o['status'] == statusFilter).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No donations in this category"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final order = filtered[index];
        final donation = order['donationId'] ?? {};
        final orderId = order['_id'];
        final donationId = donation['_id'];
        final status = order['status'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (donation['image'] != null &&
                  donation['image'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    donation['image'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['description'] ?? 'No description',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Qty: ${donation['quantity'] ?? 'N/A'}"),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Status: $status",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (status == 'claimed')
                          TextButton(
                            onPressed: () => confirmReceived(orderId),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            child: const Text("Confirm Received"),
                          ),
                      ],
                    ),
                    if (status == 'delivered')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            "Rate this donation:",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          RatingBar.builder(
                            initialRating:
                                (userRatings[donationId] ?? 0).toDouble(),
                            minRating: 1,
                            allowHalfRating: false,
                            ignoreGestures: userRatings[donationId] != null,
                            itemCount: 5,
                            itemSize: 28,
                            itemBuilder:
                                (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (rating) async {
                              final success =
                                  await DonationService.rateDonation(
                                    donationId,
                                    rating.toInt(),
                                  );
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Thanks for rating!"),
                                  ),
                                );
                                setState(() {
                                  userRatings[donationId] = rating.toInt();
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to submit rating"),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("My Claimed Donations"),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Claimed"),
            Tab(text: "On Delivery"),
            Tab(text: "Ended"),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildList('claimed'),
                  _buildList('in-transit'),
                  _buildList('delivered'),
                ],
              ),
    );
  }
}
