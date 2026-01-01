import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'court_list_screen.dart';
import 'profile/my_bookings_screen.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

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
    final user = AuthService().currentUser;
    final userId = user?.uid;
    final userEmail = user?.email ?? "Player";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Very light grey-blue (Cleaner)
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("CourtTime+", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      ),
      drawer: _buildDrawer(context, userEmail, userId),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with Decorative Circles
            _buildHeader(userId),

            // 2. Stats Section (Floating)
            Transform.translate(
              offset: const Offset(0, -60), // Pull up higher
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsSection(userId),
              ),
            ),

            // 3. Action Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Find and Book Available Courts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSportCard(
                    context,
                    title: "Badminton",
                    subtitle: "Your Game Starts Here",
                    icon: Icons.sports_tennis,
                    color: Colors.white,
                    // Modern Gradient: Orange/Pink
                    gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CourtListScreen(sportType: 'Badminton'))),
                  ),
                  const SizedBox(height: 20),
                  _buildSportCard(
                    context,
                    title: "Futsal",
                    subtitle: "Kick Off Without Delay",
                    icon: Icons.sports_soccer,
                    color: Colors.white,
                    // Modern Gradient: Emerald/Teal
                    gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CourtListScreen(sportType: 'Futsal'))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(String? userId) {
    return Container(
      width: double.infinity,
      // Increased bottom padding to accommodate the floating card overlap
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 90), 
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 152, 115, 255)], // Blue to Purple modern gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Decor Circle
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, snapshot) {
              String name = "Player";
              if (snapshot.hasData && snapshot.data!.exists) {
                name = snapshot.data!['name'] ?? "Player";
                // Capitalize first letter
                if (name.isNotEmpty) {
                  name = name[0].toUpperCase() + name.substring(1);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0, pending = 0, approved = 0, rejected = 0, completed = 0, cancelled = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          for (var doc in docs) {
            final status = doc['status'] ?? '';
            // Normalized comparison (ignore case)
            String s = status.toString().toLowerCase();
            if (s == 'pending') pending++;
            else if (s == 'approved') approved++;
            else if (s == 'rejected') rejected++;
            else if (s == 'completed') completed++;
            else if (s == 'cancelled') cancelled++;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // Softer shadow
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Row: Total Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total.toString(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF333333)),
                      ),
                      const Text("Total Bookings", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.blueAccent),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // Status Pills Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusPill("Pending", pending, Colors.orange),
                  _buildStatusPill("Approved", approved, Colors.green), // Changed 'Approved' to 'Booked' for cleaner UI text
                  _buildStatusPill("Completed", completed, Colors.blue),
                  _buildStatusPill("Rejected", rejected, Colors.red),
                  _buildStatusPill("Cancelled", cancelled, Colors.grey),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // New Design: Status Pill
  Widget _buildStatusPill(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Light pastel background
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: color.withOpacity(0.9)
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSportCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, // Slightly taller
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -30,
              bottom: -30,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: gradientColors[1], size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String userEmail, String? userId) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  return Text(
                    snapshot.data!['name'] ?? "Player",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  );
                }
                return const Text("Player");
              },
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white
              ),
              child: Center(
                child: Text(
                  userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "P",
                  style: const TextStyle(fontSize: 28, color: Color(0xFF4568DC), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Color.fromARGB(255, 152, 115, 255)], // Matches header
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(Icons.history_rounded, color: Colors.grey[700]),
            title: Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingsScreen())
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.red.withOpacity(0.05),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}