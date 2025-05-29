import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';

class EditDonationScreen extends StatefulWidget {
  final Map<String, dynamic> donation;

  const EditDonationScreen({super.key, required this.donation});

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  late TextEditingController descriptionController;
  late TextEditingController quantityController;
  DateTime? selectedDate;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(
      text: widget.donation['description'],
    );
    quantityController = TextEditingController(
      text: widget.donation['quantity'].toString(),
    );

    if (widget.donation['expiresAt'] != null) {
      selectedDate = DateTime.parse(widget.donation['expiresAt']);
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> updateDonation() async {
    setState(() => isSubmitting = true);
    final updatedData = {
      'description': descriptionController.text,
      'quantity': int.tryParse(quantityController.text) ?? 0,
      if (selectedDate != null) 'expiresAt': selectedDate!.toIso8601String(),
    };

    final success = await DonationService.updateDonation(
      widget.donation['_id'],
      updatedData,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update donation')),
      );
    }

    setState(() => isSubmitting = false);
  }

  String getFormattedDate() {
    if (selectedDate == null) return 'Select Expire Date';
    return DateFormat.yMMMMd().format(selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Donation'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Expire Date"),
              subtitle: Text(getFormattedDate()),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: pickDate,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : updateDonation,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child:
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
