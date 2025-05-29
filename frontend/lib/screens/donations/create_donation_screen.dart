import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/donation_service.dart';
import '../../firebase/image_upload.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  DateTime? selectedDateTime;
  File? selectedImage;
  Position? location;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {});
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 4)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitDonation() async {
    try {
      if (descriptionController.text.isEmpty ||
          quantityController.text.isEmpty ||
          selectedDateTime == null ||
          selectedImage == null ||
          location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
        return;
      }

      String imageUrl =
          await ImageUploader.uploadImage(selectedImage!) ??
          "https://via.placeholder.com/150?text=Upload+Failed";

      final success = await DonationService.createDonation(
        description: descriptionController.text,
        quantity: quantityController.text,
        expiresAt: selectedDateTime!,
        imageUrl: imageUrl,
        lat: location!.latitude,
        lng: location!.longitude,
      );

      if (success) {
        final userId = await AuthService.getUserId();
        if (userId != null) {
          await NotificationService.createNotification(
            userId: userId,
            message: "Your donation was created successfully!",
            type: 'donation',
          );
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Success"),
                content: const Text("Donation submitted successfully!"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Donation failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong: $e")));
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("Create Donation"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            buildTextField(
              controller: descriptionController,
              label: "Food Description",
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: quantityController,
              label: "Quantity",
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.timer),
              label: Text(
                selectedDateTime == null
                    ? "Pick Expiry Time"
                    : selectedDateTime.toString(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Upload Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(selectedImage!, height: 150),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitDonation,
              icon: const Icon(Icons.check_circle),
              label: const Text("Submit Donation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
