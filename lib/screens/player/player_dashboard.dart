import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'court_list_screen.dart';
import 'profile/my_bookings_screen.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  // Logout Function
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
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        title: const Text("CourtTime+"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    return Text(snapshot.data!['name'] ?? "Player");
                  }
                  return const Text("Player");
                },
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              decoration: const BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const MyBookingsScreen())
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // Changed to ScrollView to prevent overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // 1. WELCOME HEADER (Blue Section)
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fetch Name Dynamically
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                    builder: (context, snapshot) {
                      String name = "Player";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        name = snapshot.data!['name'] ?? "Player";
                      }
                      return Text(
                        "Hi, $name! 👋",
                        style: const TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ready to find your next game?",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ====================================================
            // 2. STATS CARDS (Overlapping the Blue Header)
            // ====================================================
            Transform.translate(
              offset: const Offset(0, -20), // Move up by 20px
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // STREAM BUILDER FOR BOOKING COUNTS
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    
                    // Default values while loading
                    int totalBookings = 0;
                    int pendingBookings = 0;

                    if (snapshot.hasData) {
                      final docs = snapshot.data!.docs;
                      totalBookings = docs.length;
                      // Filter list to count pending
                      pendingBookings = docs.where((doc) => doc['status'] == 'Pending').length;
                    }

                    return Row(
                      children: [
                        // TOTAL CARD
                        Expanded(
                          child: _buildStatCard(
                            label: "Total Bookings",
                            count: totalBookings.toString(),
                            icon: Icons.bookmark_added,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // PENDING CARD
                        Expanded(
                          child: _buildStatCard(
                            label: "Pending",
                            count: pendingBookings.toString(),
                            icon: Icons.hourglass_top,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ====================================================
            // 3. BROWSE SPORTS
            // ====================================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Browse by Sport",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Sports Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, // Important for usage inside SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
                crossAxisCount: 2, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildSportCard(
                    context, 
                    title: "Badminton", 
                    icon: Icons.sports_tennis, 
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CourtListScreen(sportType: 'Badminton')),
                    )
                  ),
                  _buildSportCard(
                    context, 
                    title: "Futsal", 
                    icon: Icons.sports_soccer, 
                    color: Colors.greenAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CourtListScreen(sportType: 'Futsal')),
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // WIDGET: Stats Card
  Widget _buildStatCard({required String label, required String count, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  // WIDGET: Sport Card
  Widget _buildSportCard(BuildContext context, {
    required String title, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Book Now", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}