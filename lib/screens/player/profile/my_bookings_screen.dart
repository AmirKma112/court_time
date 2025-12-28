import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/booking_card.dart';
import 'package:court_time/screens/player/booking/slot_selection_screen.dart'; //reshedule 

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  
  @override
  void initState() {
    super.initState();
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
      final Timestamp? bookingTimestamp = data['bookingDate'];
      
      if (bookingTimestamp != null) {
        DateTime bookingDate = bookingTimestamp.toDate();

        // If booking is more than 1 hours in the past, mark as Completed
        if (bookingDate.isBefore(now.subtract(const Duration(hours: 1)))) {
          await DatabaseService().updateBookingStatus(doc.id, 'Completed');
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
        content: const Text("Are you sure you want to cancel your request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No, Keep it"),
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
          const SnackBar(content: Text("Booking cancelled successfully.")),
        );
      }
    }
  }

  // ==============================================================
  // 3. RESCHEDULE LOGIC (Update Time)
  // ==============================================================
  void _rescheduleBooking(BookingModel booking) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch Court Details so we can open the selection screen
    final court = await DatabaseService().getCourtById(booking.courtId);
    
    // Hide Loading
    if (mounted) Navigator.pop(context);

    if (court != null && mounted) {
      // Navigate to SlotSelectionScreen in "Update Mode"
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SlotSelectionScreen(
            court: court,          
            bookingId: booking.id, // Passing ID triggers "Update Mode"
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Court details not found.")),
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
    // Define which statuses belong to which tab
    final List<String> activeStatuses = ['Pending', 'Approved', 'Confirmed'];
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

            // 🔒 RULES:
            // 1. Only 'Pending' bookings can be Modified or Cancelled.
            // 2. 'Approved' bookings are locked (must contact owner).
            final bool isEditable = booking.status == 'Pending';

            return BookingCard(
              booking: booking,
              trailing: isActive
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RESCHEDULE BUTTON (Blue Edit Icon)
                      if (isEditable)
                        IconButton(
                          icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                          tooltip: "Reschedule / Update Time",
                          onPressed: () => _rescheduleBooking(booking),
                        ),
                      
                      // CANCEL BUTTON (Red X Icon)
                      if (isEditable)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: "Cancel Request",
                          onPressed: () => _cancelBooking(booking.id),
                        ),
                    ],
                  )
                : null, // No buttons for History or Approved bookings
            );
          },
        );
      },
    );
  }
}