import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'owner_manage_bookings.dart';
import 'owner_manage_courts.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

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
    final ownerId = AuthService().getCurrentUserId();
    
    // Safety check for login
    if (ownerId == null) return const Scaffold(body: Center(child: Text("Loading...")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Venue Owner",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Business Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your venue and check activity.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 1. MAIN ACTION GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildOwnerCard(
                  context,
                  title: "Incoming\nRequests",
                  subtitle: "Action Required",
                  icon: Icons.notifications_active_rounded,
                  color: Colors.orange,
                  gradient: [Colors.orange.shade300, Colors.deepOrange],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerManageBookings()),
                    );
                  },
                ),
                _buildOwnerCard(
                  context,
                  title: "Manage\nCourts",
                  subtitle: "Add/Edit Venues",
                  icon: Icons.stadium_rounded,
                  color: Colors.green,
                  gradient: [Colors.green.shade300, Colors.teal],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerManageCourts()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. BOOKING COUNTS SECTION
            const Text(
              "Booking Statistics",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // --- NEW: Pending Requests ---
                  _buildStatTile(ownerId, "Pending Requests", Icons.hourglass_top_rounded, Colors.orange, 'Pending'),
                  const Divider(),
                  
                  // Approved
                  _buildStatTile(ownerId, "Approved Bookings", Icons.check_circle, Colors.green, 'Approved'),
                  const Divider(),
                  
                  // Completed
                  _buildStatTile(ownerId, "Completed Games", Icons.history, Colors.blue, 'Completed'),
                  const Divider(),
                  
                  // Cancelled
                  _buildStatTile(ownerId, "Cancelled Bookings", Icons.cancel, Colors.grey, 'Cancelled'),
                  const Divider(),
                  
                  // Rejected
                  _buildStatTile(ownerId, "Rejected Requests", Icons.block, Colors.red, 'Rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Stat Tile with FutureBuilder ---
  Widget _buildStatTile(String ownerId, String title, IconData icon, Color color, String status) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      // Fetch the count from Firestore directly
      trailing: FutureBuilder<AggregateQuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: ownerId)
            .where('status', isEqualTo: status)
            .count()
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 16, height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2)
            );
          }
          if (snapshot.hasError) {
            return const Text("-", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
          }
          
          final count = snapshot.data?.count ?? 0;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                color: color
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REUSABLE MODERN CARD WIDGET ---
  Widget _buildOwnerCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  height: 100, width: 100,
                  decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}