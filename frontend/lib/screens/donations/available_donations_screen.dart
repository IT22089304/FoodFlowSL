import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../services/donation_service.dart';
import '../../utils/distance_utils.dart';
import '../donations/donation_details_screen.dart';

class AvailableDonationsScreen extends StatefulWidget {
  const AvailableDonationsScreen({super.key});

  @override
  State<AvailableDonationsScreen> createState() =>
      _AvailableDonationsScreenState();
}

class _AvailableDonationsScreenState extends State<AvailableDonationsScreen> {
  Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<BitmapDescriptor> getMarkerFromImageUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 100);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final resizedBytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(resizedBytes);
    } catch (e) {
      print("⚠️ Failed to load image marker: $e");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _loadMapData() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final allDonations = await DonationService.getAllAvailableDonations();

      final filtered =
          allDonations.where((donation) {
            final loc = donation['location'];
            if (loc == null || loc['lat'] == null || loc['lng'] == null)
              return false;

            final distance = DistanceUtils.calculateDistance(
              position.latitude,
              position.longitude,
              loc['lat'],
              loc['lng'],
            );
            return distance <= 100.0 && donation['status'] == 'pending';
          }).toList();

      Set<Marker> markers = {};
      for (var d in filtered) {
        final lat = d['location']['lat'];
        final lng = d['location']['lng'];

        // ✅ Extract image URL
        final imageUrl =
            d['image'] is String ? d['image'] : d['image']?['url']?.toString();
        if (imageUrl == null || imageUrl.isEmpty) continue;

        final icon = await getMarkerFromImageUrl(imageUrl);

        // ✅ Ensure donorId and image are clean strings
        if (d['image'] is Map && d['image']['url'] != null) {
          d['image'] = d['image']['url'];
        }

        if (d['donorId'] is Map && d['donorId']['_id'] != null) {
          d['donorId'] = d['donorId']['_id'].toString();
        } else if (d['donorId'] is! String) {
          d['donorId'] = d['donorId'].toString();
        }

        markers.add(
          Marker(
            markerId: MarkerId(d['_id']),
            position: LatLng(lat, lng),
            icon: icon,
            infoWindow: InfoWindow(
              title: d['description'] ?? 'No description',
              snippet: 'Qty: ${d['quantity'] ?? 'N/A'}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DonationDetailsScreen(donationId: d['_id']),
                  ),
                );
              },
            ),
          ),
        );
      }

      setState(() {
        _currentPosition = position;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading map data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyMapStyle(GoogleMapController controller) async {
    final style = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style.json');
    controller.setMapStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Donations (within 20km)"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          _isLoading || _currentPosition == null
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 13,
                ),
                myLocationEnabled: true,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) async {
                  _mapController.complete(controller);
                  await _applyMapStyle(controller);
                },
                minMaxZoomPreference: const MinMaxZoomPreference(7, 18),
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              ),
    );
  }
}
