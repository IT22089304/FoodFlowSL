import 'package:flutter/material.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';

class DonorProfileScreen extends StatefulWidget {
  final String donorId;

  const DonorProfileScreen({super.key, required this.donorId});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  Map<String, dynamic>? donor;
  List<dynamic> donations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDonorData();
  }

  Future<void> loadDonorData() async {
    final donorDetails = await AuthService.getUserById(widget.donorId);
    final allDonations = await DonationService.getDonationsByUser(
      widget.donorId,
    );

    // ✅ Filter only confirmed/completed donations (status == delivered)
    final completed =
        allDonations.where((d) => d['status'] == 'delivered').toList();

    setState(() {
      donor = donorDetails;
      donations = completed.take(5).toList(); // ✅ limit to 5
      isLoading = false;
    });
  }

  double getAverageRating() {
    if (donations.isEmpty) return 0.0;
    final rated = donations.where((d) => d['rating'] != null).toList();
    if (rated.isEmpty) return 0.0;
    final total = rated.fold(
      0.0,
      (sum, d) => sum + (d['rating'] as num).toDouble(),
    );
    return total / rated.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("Donor Profile"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : donor == null
              ? const Center(child: Text("Donor not found"))
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, size: 64, color: Colors.orange),
                    const SizedBox(height: 10),
                    Text(
                      donor!['name'] ?? 'No name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(donor!['email'] ?? 'No email'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text("Completed Donations: ${donations.length}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          "Average Rating: ${getAverageRating().toStringAsFixed(1)} ⭐",
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Recent Donations:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: donations.length,
                        itemBuilder: (context, index) {
                          final d = donations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              leading:
                                  d['image'] != null &&
                                          d['image'].toString().isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          d['image'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Colors.orange,
                                      ),
                              title: Text(d['description'] ?? 'No description'),
                              subtitle: Text("Qty: ${d['quantity']}"),
                              trailing:
                                  d['rating'] != null
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          Text('${d['rating']}'),
                                        ],
                                      )
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
