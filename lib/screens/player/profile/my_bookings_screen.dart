import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/booking_card.dart';
import 'package:court_time/screens/player/booking/slot_selection_screen.dart';

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

  void _checkExpiredBookings() async {
    final userId = AuthService().getCurrentUserId();
    if (userId == null) return;

    final now = DateTime.now();
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
        if (bookingDate.isBefore(now.subtract(const Duration(hours: 1)))) {
          await DatabaseService().updateBookingStatus(doc.id, 'Completed');
        }
      }
    }
  }

  void _cancelBooking(String bookingId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure you want to cancel your request?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No, Keep it"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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

  void _rescheduleBooking(BookingModel booking) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final court = await DatabaseService().getCourtById(booking.courtId);
    
    if (mounted) Navigator.pop(context);

    if (court != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SlotSelectionScreen(
            court: court,          
            bookingId: booking.id, 
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
        backgroundColor: const Color(0xFFF5F7FA), // Light grey background
        appBar: AppBar(
          title: const Text(
            "My Bookings",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF448AFF)], // Modern Blue Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30.0),
            ),
          ),
        ),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Active"),
                  Tab(text: "History"),
                ],
              ),
            ),
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
    final List<String> activeStatuses = ['Pending', 'Approved'];
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.calendar_today : Icons.history,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isActive ? "No active bookings" : "No past history",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive ? "Your upcoming games will appear here." : "Your completed games will appear here.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final booking = BookingModel.fromMap(data, docs[index].id);
            final bool isEditable = booking.status == 'Pending';

            return BookingCard(
              booking: booking,
              actionButtons: isActive && isEditable
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text("Reschedule"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _rescheduleBooking(booking),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text("Cancel"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _cancelBooking(booking.id),
                        ),
                      ),
                    ],
                  )
                : null,
            );
          },
        );
      },
    );
  }
}