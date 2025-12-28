import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/booking_card.dart'; 

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  
  @override
  void initState() {
    super.initState();
    // ⚡ Run this check every time the screen opens
    _checkExpiredBookings();
  }

  // ==============================================================
  // 1. AUTO-COMPLETE LOGIC (Moves old bookings to History)
  // ==============================================================
  void _checkExpiredBookings() async {
    final userId = AuthService().getCurrentUserId();
    if (userId == null) return;

    final now = DateTime.now();

    // Get all "Approved" bookings for this user
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Approved') 
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Check the Date
      final Timestamp? bookingTimestamp = data['bookingDate'];
      if (bookingTimestamp != null) {
        DateTime bookingDate = bookingTimestamp.toDate();

        // If the booking date is BEFORE today (in the past)
        if (bookingDate.isBefore(now.subtract(const Duration(hours: 2)))) {
          // We add a 2-hour buffer so it doesn't disappear immediately when the game starts
          
          // Update status to 'Completed'
          await DatabaseService().updateBookingStatus(doc.id, 'Completed');
          debugPrint("Auto-completed booking: ${doc.id}");
        }
      }
    }
  }

  // ==============================================================
  // 2. CANCEL LOGIC
  // ==============================================================
  void _cancelBooking(String bookingId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep it"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().updateBookingStatus(bookingId, 'Cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking cancelled.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    // Active = Pending or Approved
    final List<String> activeStatuses = ['Pending', 'Approved', 'Confirmed'];
    // History = Rejected, Cancelled, OR Completed
    final List<String> historyStatuses = ['Rejected', 'Cancelled', 'Completed'];

    final filterStatuses = isActive ? activeStatuses : historyStatuses;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: filterStatuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          // If error, print it (this helps catch index errors too)
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

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

            return BookingCard(
              booking: booking,
              trailing: isActive 
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: "Cancel",
                    onPressed: () => _cancelBooking(booking.id),
                  ) 
                : null, // No cancel button in history
            );
          },
        );
      },
    );
  }
}