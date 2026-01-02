import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'court_list_screen.dart';
import 'profile/my_bookings_screen.dart';
import 'profile/my_profile_screen.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  void _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of your account?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

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
      backgroundColor: const Color(0xFFF4F6FA), // Premium light grey-blue background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      drawer: _buildDrawer(context, userEmail, userId),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Area
            _buildHeader(userId),

            // 2. Floating Stats Section
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStatsSection(userId),
              ),
            ),

            // 3. Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Start a New Game",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w800, 
                      color: Color(0xFF2D3142)
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSportCard(
                    context,
                    title: "Badminton",
                    subtitle: "Book a court & smash it!",
                    icon: Icons.sports_tennis,
                    // Gradient: Warm Orange to Red
                    gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CourtListScreen(sportType: 'Badminton'))),
                  ),
                  const SizedBox(height: 20),
                  _buildSportCard(
                    context,
                    title: "Futsal",
                    subtitle: "Gather your team & play.",
                    icon: Icons.sports_soccer,
                    // Gradient: Cool Teal to Green
                    gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CourtListScreen(sportType: 'Futsal'))),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. HEADER WIDGET ---
  Widget _buildHeader(String? userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent, blurRadius: 20, offset: Offset(0, 10), spreadRadius: -10)
        ]
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decor Circle 1
          Positioned(
            right: -60, top: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            ),
          ),
          // Decor Circle 2
          Positioned(
            left: -40, bottom: -60,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, snapshot) {
              String name = "Player";
              if (snapshot.hasData && snapshot.data!.exists) {
                name = snapshot.data!['name'] ?? "Player";
                if (name.isNotEmpty) name = name[0].toUpperCase() + name.substring(1);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.waving_hand_rounded, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text("Hi, $name", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ready to play today?",
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 2. STATS SECTION WIDGET ---
  Widget _buildStatsSection(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        int total = 0, pending = 0, approved = 0, rejected = 0, completed = 0, cancelled = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          for (var doc in docs) {
            String s = (doc['status'] ?? '').toString().toLowerCase();
            if (s == 'pending') pending++;
            else if (s == 'approved') approved++;
            else if (s == 'rejected') rejected++;
            else if (s == 'completed') completed++;
            else if (s == 'cancelled') cancelled++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2962FF).withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(total.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
                      const Text("Total Bookings", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    height: 55, width: 55,
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2962FF), size: 30),
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusPill("Pending", pending, Colors.orange),
                  _buildStatusPill("Approved", approved, Colors.green),
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

  Widget _buildStatusPill(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          height: 45, width: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5)
          ),
          child: Center(
            child: Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- 3. SPORT CARD WIDGET ---
  Widget _buildSportCard(BuildContext context, {
    required String title, required String subtitle, required IconData icon, required List<Color> gradientColors, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.15))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.arrow_forward_rounded, color: gradientColors[1], size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. DRAWER WIDGET ---
  Widget _buildDrawer(BuildContext context, String userEmail, String? userId) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(30))),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2962FF), Color(0xFF448AFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                  child: CircleAvatar(
                    radius: 30, backgroundColor: Colors.white,
                    child: Text(userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "P", style: const TextStyle(fontSize: 26, color: Color(0xFF2962FF), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                  builder: (context, snapshot) {
                    String name = "Player";
                    if (snapshot.hasData && snapshot.data!.exists) name = snapshot.data!['name'] ?? "Player";
                    return Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 4),
                Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerTile(icon: Icons.calendar_month_rounded, title: "My Bookings", color: Colors.blueAccent, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
                }),
                const SizedBox(height: 8),
                _buildDrawerTile(icon: Icons.person_rounded, title: "My Profile", color: Colors.purpleAccent, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProfileScreen()));
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.red.withOpacity(0.08),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}