import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../firebase/image_upload.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  File? newProfileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final data = await AuthService.getProfile();

    if (data != null) {
      setState(() {
        user = data;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        mobileController.text = data['mobileNumber'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        user = null;
        isLoading = false;
      });
    }
  }

  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        newProfileImage = File(image.path);
      });

      // Upload to Firebase and update profile
      final imageUrl = await ImageUploader.uploadImage(
        newProfileImage!,
        folder: 'profile_pictures',
      );
      if (imageUrl != null) {
        await AuthService.updateProfile({'profilePic': imageUrl});
        await fetchProfile(); // Refresh profile data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile image')),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    final updated = await AuthService.updateProfile({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'mobileNumber': mobileController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated ? "Profile updated" : "Update failed"),
        backgroundColor: updated ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await AuthService.logoutUser();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
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
        title: const Text("My Profile"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text("Failed to load user info"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickProfileImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.orangeAccent,
                        backgroundImage:
                            newProfileImage != null
                                ? FileImage(newProfileImage!)
                                : (user!['profilePic'] != null &&
                                    user!['profilePic'].toString().isNotEmpty)
                                ? NetworkImage(user!['profilePic'])
                                    as ImageProvider
                                : null,
                        child:
                            user!['profilePic'] == null ||
                                    user!['profilePic'].toString().isEmpty
                                ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildTextField(controller: nameController, label: 'Name'),
                    const SizedBox(height: 16),
                    buildTextField(
                      controller: emailController,
                      label: 'Email',
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    buildTextField(
                      controller: mobileController,
                      label: 'Mobile Number',
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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
