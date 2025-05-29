import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/donations/create_donation_screen.dart';
import 'screens/dashboard/donor_dashboard.dart';
import 'screens/dashboard/receiver_dashboard.dart';
import 'firebase/firebase_config.dart'; // your Firebase options file
import 'screens/donations/my_donations_screen.dart';
import 'screens/donations/my_claimed_donations_screen.dart';
import 'screens/donations/edit_donation_screen.dart';
import 'screens/dashboard/volunteer_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/dashboard/LoadingScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // from firebase_config.dart
  );
  runApp(const FoodFlowApp());
}

class FoodFlowApp extends StatelessWidget {
  const FoodFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodFlowSL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => LoadingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DonorDashboard(),
        '/donation/create': (context) => const CreateDonationScreen(),
        '/donation/my': (context) => const MyDonationsScreen(),
        '/dashboard/receiver': (context) => const ReceiverDashboard(),
        '/dashboard/volunteer': (context) => const VolunteerDashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/donation/claimed': (context) => const MyClaimedDonationsScreen(),
        '/donation/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EditDonationScreen(donation: Map<String, dynamic>.from(args));
        },
      },
    );
  }
}
