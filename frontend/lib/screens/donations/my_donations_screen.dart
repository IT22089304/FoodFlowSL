import 'package:flutter/material.dart';
import '../../services/donation_service.dart';
import '../donations/EditDonationScreen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> donations = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchDonations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchDonations() async {
    final data = await DonationService.getMyDonations();
    setState(() {
      donations = data;
      isLoading = false;
    });
  }

  Future<void> deleteDonation(String donationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Donation"),
            content: const Text(
              "Are you sure you want to delete this donation?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await DonationService.deleteDonation(donationId);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Donation deleted")));
        fetchDonations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete donation")),
        );
      }
    }
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final bool isPending = donation['status'] == 'pending';

    return GestureDetector(
      onTap: () {
        if (isPending) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditDonationScreen(donation: donation),
            ),
          ).then((_) => fetchDonations());
        }
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                donation['image'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation['description'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Qty: ${donation['quantity']}'),
                  Text('Status: ${donation['status']}'),
                  if (isPending)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => deleteDonation(donation['_id']),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Delete"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabContent(String tab) {
    List<dynamic> filtered = [];

    if (tab == 'active') {
      filtered = donations.where((d) => d['status'] == 'pending').toList();
    } else if (tab == 'claimed') {
      filtered =
          donations
              .where(
                (d) => d['status'] != 'pending' && d['status'] != 'expired',
              )
              .toList();
    } else if (tab == 'expired') {
      filtered = donations.where((d) => d['status'] == 'expired').toList();
    }

    if (filtered.isEmpty) {
      return const Center(child: Text("No donations found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildDonationCard(filtered[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text('My Donations'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Claimed'),
            Tab(text: 'Expired'),
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
                  buildTabContent('active'),
                  buildTabContent('claimed'),
                  buildTabContent('expired'),
                ],
              ),
    );
  }
}
