import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';
import '../orders/available_orders_list_screen.dart';

class OrderMapScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> donation;
  final String receiverId;

  const OrderMapScreen({
    super.key,
    required this.orderId,
    required this.donation,
    required this.receiverId,
  });

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  Map<String, dynamic>? locations;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final loc = await OrderService.getOrderLocations(widget.orderId);
    setState(() {
      locations = loc;
      isLoading = false;
    });
  }

  Future<void> handleAccept() async {
    final success = await OrderService.claimDelivery(widget.donation['_id']);
    if (success) {
      await NotificationService.createNotification(
        userId: widget.receiverId,
        message: "A volunteer has accepted your order",
        type: "donation",
        targetDonationId: widget.donation['_id'],
        targetDonationTitle: widget.donation['description'] ?? 'your donation',
        targetDonationImage: widget.donation['image'],
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/orders/available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delivery claimed successfully")),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to claim delivery")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Location Map"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : locations == null
              ? const Center(child: Text("Failed to load locations"))
              : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        locations!['donorLocation']['lat'],
                        locations!['donorLocation']['lng'],
                      ),
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("donor"),
                        position: LatLng(
                          locations!['donorLocation']['lat'],
                          locations!['donorLocation']['lng'],
                        ),
                        infoWindow: const InfoWindow(title: "Donor"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId("receiver"),
                        position: LatLng(
                          locations!['receiverLocation']['lat'],
                          locations!['receiverLocation']['lng'],
                        ),
                        infoWindow: const InfoWindow(title: "Receiver"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    },
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      onPressed: handleAccept,
                      icon: const Icon(Icons.check),
                      label: const Text("Accept Delivery"),
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
                ],
              ),
    );
  }
}
