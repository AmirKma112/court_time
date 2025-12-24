import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'court_list_screen.dart';
// import 'profile/my_bookings_screen.dart'; // We will create this next

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({Key? key}) : super(key: key);

  // Logout Function
  void _handleLogout(BuildContext context) async {
    // 1. Sign out from Firebase
    await AuthService().signOut();
    
    if (!context.mounted) return;
    
    // 2. Return to Login Screen (Remove all history)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user email for display
    final userEmail = AuthService().currentUser?.email ?? "Player";

    return Scaffold(
      appBar: AppBar(
        title: const Text("CourtTime+"),
        backgroundColor: Colors.blueAccent,
      ),
      // SIDE DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Welcome!"),
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
              onTap: () => Navigator.pop(context), // Close drawer
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                // Navigate to Booking History
                //  Navigator.push(
                //   context, 
                //   MaterialPageRoute(builder: (context) => const MyBookingsScreen())
                // );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.blueAccent.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ready to play?",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Find the perfect court for your game today.",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              "Browse by Sport",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sport Categories Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildSportCard(
                    context, 
                    title: "Badminton", 
                    icon: Icons.sports_tennis, 
                    color: Colors.orangeAccent,
                    imagePath: "assets/badminton.png", // Optional: Add assets later if needed
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourtListScreen(sportType: 'Badminton'),
                        ),
                      );
                    }
                  ),
                  _buildSportCard(
                    context, 
                    title: "Futsal", 
                    icon: Icons.sports_soccer, 
                    color: Colors.greenAccent,
                    imagePath: "assets/futsal.png",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourtListScreen(sportType: 'Futsal'),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Sport Cards
  Widget _buildSportCard(BuildContext context, {
    required String title, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Book Now",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}