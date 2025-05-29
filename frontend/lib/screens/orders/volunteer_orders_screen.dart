import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';

class VolunteerOrdersScreen extends StatefulWidget {
  const VolunteerOrdersScreen({super.key});

  @override
  State<VolunteerOrdersScreen> createState() => _VolunteerOrdersScreenState();
}

class _VolunteerOrdersScreenState extends State<VolunteerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allOrders = [];
  Map<String, dynamic> orderUserDetails = {};
  bool isLoading = true;
  String? myId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    final data = await OrderService.getMyAssignedOrders();
    final id = await OrderService.getCurrentUserId();
    setState(() {
      allOrders = data;
      myId = id;
      isLoading = false;
    });

    for (var order in data) {
      final orderId = order['_id'];
      final details = await OrderService.getOrderUsers(orderId);
      setState(() {
        orderUserDetails[orderId] = details;
      });
    }
  }

  Future<void> markDelivered(String orderId) async {
    final success = await OrderService.confirmDelivery(orderId);

    if (success) {
      final order = allOrders.firstWhere((o) => o['_id'] == orderId);
      final donation = order['donationId'];
      final donorId = donation['donorId'];
      final receiverId = order['receiverId'];
      final donationTitle = donation['description'] ?? 'your donation';
      final donationImage = donation['image'];

      if (donorId != null) {
        await NotificationService.createNotification(
          userId: donorId,
          message: "Your donation '$donationTitle' has been delivered!",
          type: "donation",
          targetDonationId: donation['_id'],
          targetDonationTitle: donationTitle,
          targetDonationImage: donationImage,
        );
      }

      if (receiverId != null) {
        await NotificationService.createNotification(
          userId: receiverId,
          message: "Your claimed donation '$donationTitle' has been delivered!",
          type: "donation",
          targetDonationId: donation['_id'],
          targetDonationTitle: donationTitle,
          targetDonationImage: donationImage,
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as delivered")));
      fetchOrders();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update status")));
    }
  }

  Widget buildList(String statusFilter) {
    final filtered =
        allOrders
            .where(
              (o) => o['status'] == statusFilter && o['volunteerId'] == myId,
            )
            .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No orders in this category"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        final donation = order['donationId'];
        final orderId = order['_id'];
        final details = orderUserDetails[orderId] ?? {};

        final donor = details['donor'] ?? {};
        final receiver = details['receiver'] ?? {};

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donation['image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      donation['image'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),

                Text(
                  donation['description'] ?? 'No description',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Qty: ${donation['quantity']}"),
                const SizedBox(height: 6),
                Text(
                  "Status: ${order['status']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 20),

                Text(
                  "Donor: ${donor['name'] ?? 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text("📞 ${donor['mobileNumber'] ?? 'N/A'}"),
                const SizedBox(height: 8),
                Text(
                  "Receiver: ${receiver['name'] ?? 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text("📞 ${receiver['mobileNumber'] ?? 'N/A'}"),

                if (statusFilter == 'in-transit')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => markDelivered(orderId),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      label: const Text("Mark as Delivered"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
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
        title: const Text("My Orders"),
        backgroundColor: Colors.orange,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "Active"), Tab(text: "Ended")],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : TabBarView(
                controller: _tabController,
                children: [buildList('in-transit'), buildList('delivered')],
              ),
    );
  }
}
