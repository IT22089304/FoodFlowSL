import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';
import './order_map_screen.dart';

class AvailableOrdersListScreen extends StatefulWidget {
  const AvailableOrdersListScreen({super.key});

  @override
  State<AvailableOrdersListScreen> createState() =>
      _AvailableOrdersListScreenState();
}

class _AvailableOrdersListScreenState extends State<AvailableOrdersListScreen> {
  List<dynamic> availableOrders = [];
  Map<String, dynamic> orderUserDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAvailableOrders();
  }

  Future<void> fetchAvailableOrders() async {
    final data = await OrderService.getMyAvailableOrders();
    setState(() {
      availableOrders = data;
      isLoading = false;
    });

    // 🔄 Fetch donor/receiver details for each order
    for (var order in data) {
      final orderId = order['_id'];
      final details = await OrderService.getOrderUsers(orderId);
      setState(() {
        orderUserDetails[orderId] = details;
      });
    }
  }

  Future<void> claimDelivery(String donationId) async {
    final success = await OrderService.claimDelivery(donationId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delivery claimed successfully")),
      );

      final order = availableOrders.firstWhere(
        (o) => o['donationId']['_id'] == donationId,
        orElse: () => null,
      );

      if (order != null) {
        final donation = order['donationId'];
        final receiverId = order['receiverId'];
        final donationTitle = donation['description'] ?? 'your donation';
        final donationImage = donation['image'];

        if (receiverId != null) {
          await NotificationService.createNotification(
            userId: receiverId,
            message: "A volunteer has accepted your order",
            type: "donation",
            targetDonationId: donation['_id'],
            targetDonationTitle: donationTitle,
            targetDonationImage: donationImage,
          );
        }
      }

      fetchAvailableOrders();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to claim delivery")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("Available Orders"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : availableOrders.isEmpty
              ? const Center(
                child: Text(
                  "No available orders",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableOrders.length,
                itemBuilder: (context, index) {
                  final order = availableOrders[index];
                  final donation = order['donationId'];
                  final orderId = order['_id'];
                  final details = orderUserDetails[orderId] ?? {};

                  final donorName =
                      details['donor']?['name'] ?? 'Unknown Donor';
                  final receiverName =
                      details['receiver']?['name'] ?? 'Unknown Receiver';
                  final imageUrl = donation['image'];
                  final expiresAt = donation['expiresAt'];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 80,
                                    ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            donation['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Qty: ${donation['quantity'] ?? 'N/A'}"),
                          Text(
                            "Expires: ${expiresAt?.toString().split('T').first ?? 'N/A'}",
                          ),
                          const SizedBox(height: 6),
                          Text("Donor: $donorName"),
                          Text("Receiver: $receiverName"),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => OrderMapScreen(
                                        orderId: orderId,
                                        donation: donation,
                                        receiverId: order['receiverId'],
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text("View Locations"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
