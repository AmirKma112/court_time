import 'package:court_time/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// import 'admin_manage_bookings.dart'; 
// import 'admin_manage_courts.dart';   

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Logout Logic
  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.blueGrey, // Distinct Admin Color
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Grid of Management Options
            // Now cleaner with just 2 main options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Reduced children list
                children: [
                  // 1. Manage Bookings Card
                  _buildAdminCard(
                    context,
                    title: "Manage Bookings",
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                    count: "View All", 
                    onTap: () {
                      //  Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const AdminManageBookings()),
                      // );
                    },
                  ),

                  // 2. Manage Courts Card
                  _buildAdminCard(
                    context,
                    title: "Manage Courts",
                    icon: Icons.stadium,
                    color: Colors.green,
                    count: "Edit/Add",
                    onTap: () {
                      //  Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const AdminManageCourts()),
                      // );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Card Widget
  Widget _buildAdminCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey[600]
              ),
            ),
          ],
        ),
      ),
    );
  }
}