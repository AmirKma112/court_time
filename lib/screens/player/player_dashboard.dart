import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'court_list_screen.dart';
import 'profile/my_bookings_screen.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  void _handleLogout(BuildContext context) async {
    // 1. Show the Alert Dialog and wait for user choice
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Return false
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          // Logout Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true), // Return true
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // 2. if user clicked "Logout" (true)
    if (confirm == true) {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
          colors: [Color(0xFF2962FF), Color(0xFF448AFF)], // Blue to Purple modern gradient
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
      width: 280, // Fixed width for better proportions
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // 1. CUSTOM HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2962FF), Color(0xFF448AFF)], // Modern Blue Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture with Ring
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "P",
                      style: const TextStyle(
                        fontSize: 28, 
                        color: Color(0xFF2962FF), 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name (Streamed)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                  builder: (context, snapshot) {
                    String name = "Player";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      name = snapshot.data!['name'] ?? "Player";
                    }
                    return Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                
                // Email
                Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8), 
                        fontSize: 13
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerTile(
                  icon: Icons.calendar_today_rounded,
                  title: "My Bookings",
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. LOGOUT & VERSION
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.red.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Logout', 
                    style: TextStyle(
                      color: Colors.redAccent, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    )
                  ),
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(height: 16),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGET FOR DRAWER TILES ---
  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Light background matching icon color
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: Colors.grey[800],
          fontSize: 15
        )
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
      onTap: onTap,
    );
  
  }
}