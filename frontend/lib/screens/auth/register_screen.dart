import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'donor';

  // Validation error messages
  String? nameError;
  String? emailError;
  String? passwordError;

  final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  void validateName(String value) {
    setState(() {
      nameError = value.trim().isEmpty ? 'Name is required' : null;
    });
  }

  void validateEmail(String value) {
    setState(() {
      emailError =
          !_emailRegex.hasMatch(value.trim()) ? 'Enter a valid email' : null;
    });
  }

  void validatePassword(String value) {
    setState(() {
      passwordError =
          value.length < 6 ? 'Password must be at least 6 characters' : null;
    });
  }

  Future<void> handleRegister() async {
    validateName(nameController.text);
    validateEmail(emailController.text);
    validatePassword(passwordController.text);

    if (nameError != null || emailError != null || passwordError != null)
      return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Get location
    Position? position;
    if (await Permission.location.request().isGranted) {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    final success = await AuthService.registerUser(
      name,
      email,
      password,
      selectedRole,
      position.latitude,
      position.longitude,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration failed')));
    }
  }

  InputDecoration buildInputDecoration(String label, String? errorText) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_add_alt_1,
                size: 72,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                "Create Account",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              TextField(
                controller: nameController,
                decoration: buildInputDecoration('Name', nameError),
                onChanged: (value) => validateName(value),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: emailController,
                decoration: buildInputDecoration('Email', emailError),
                onChanged: (value) => validateEmail(value),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: buildInputDecoration('Password', passwordError),
                onChanged: (value) => validatePassword(value),
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'donor', child: Text('Donor')),
                  DropdownMenuItem(value: 'receiver', child: Text('Receiver')),
                  DropdownMenuItem(
                    value: 'volunteer',
                    child: Text('Volunteer'),
                  ),
                ],
                onChanged: (value) => setState(() => selectedRole = value!),
                decoration: buildInputDecoration('Select Role', null),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Register", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
