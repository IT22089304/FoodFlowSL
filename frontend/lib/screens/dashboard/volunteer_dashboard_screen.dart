import 'package:flutter/material.dart';
import '../../widgets/notification_popup.dart';
import '../orders/available_orders_list_screen.dart';
import '../orders/volunteer_orders_screen.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  OverlayEntry? _popup;

  void _toggleNotificationPopup(BuildContext context) {
    if (_popup != null) {
      _popup!.remove();
      _popup = null;
      return;
    }

    final overlay = Overlay.of(context);
    _popup = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _popup?.remove();
                    _popup = null;
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Positioned(
                top: kToolbarHeight + 10,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: NotificationPopup(
                    onClose: () {
                      _popup?.remove();
                      _popup = null;
                    },
                  ),
                ),
              ),
            ],
          ),
    );

    overlay.insert(_popup!);
  } // ✅ Properly closed here!

  @override
  void dispose() {
    _popup?.remove();
    super.dispose();
  }

  Widget buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.orange,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E9),
      appBar: AppBar(
        title: const Text("Volunteer Dashboard"),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _toggleNotificationPopup(context),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.volunteer_activism,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome, Volunteer!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            buildDashboardCard(
              icon: Icons.delivery_dining,
              title: "Available Orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AvailableOrdersListScreen(),
                  ),
                );
              },
            ),
            buildDashboardCard(
              icon: Icons.assignment_turned_in,
              title: "My Orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VolunteerOrdersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
