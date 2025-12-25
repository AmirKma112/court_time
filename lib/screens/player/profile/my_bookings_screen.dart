import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/booking_model.dart';
//import '../../../widgets/booking_card.dart'; // Ensure this widget exists

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get Current User ID
    final userId = AuthService().getCurrentUserId();

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please login first.")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          backgroundColor: Colors.blueAccent,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(userId, isActive: true),
            _buildBookingList(userId, isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(String userId, {required bool isActive}) {
    // Define status groups
    final List<String> activeStatuses = ['Pending', 'Approved', 'Confirmed'];
    final List<String> historyStatuses = ['Rejected', 'Cancelled', 'Completed'];

    final filterStatuses = isActive ? activeStatuses : historyStatuses;

    return StreamBuilder<QuerySnapshot>(
      // 2. Query: My Bookings Only
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId) // 🔒 Filter by User
          .where('status', whereIn: filterStatuses) // Filter by Status Tab
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.calendar_today : Icons.history,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isActive ? "No active bookings." : "No past history.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final booking = BookingModel.fromMap(data, docs[index].id);

            // 3. Use Reusable Widget
            //return BookingCard(booking: booking);
          },
        );
      },
    );
  }
}