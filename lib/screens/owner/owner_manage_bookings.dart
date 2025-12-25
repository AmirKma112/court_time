import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../widgets/booking_card.dart'; // Uses the shared widget

class OwnerManageBookings extends StatelessWidget {
  const OwnerManageBookings({super.key});

  // Action: Approve or Reject
  void _updateStatus(BuildContext context, String bookingId, String newStatus) async {
    try {
      await DatabaseService().updateBookingStatus(bookingId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking $newStatus!"),
            backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Current Owner ID
    final ownerId = AuthService().getCurrentUserId();

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Bookings"),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<List<BookingModel>>(
        // 2. Query Bookings for THIS Owner only
        stream: DatabaseService().getOwnerBookings(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No bookings found yet.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              // 3. Build Card with Action Buttons
              return BookingCard(
                booking: booking,
                // We pass the buttons into the 'trailing' slot of our widget
                trailing: booking.status == 'Pending' 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // REJECT BUTTON
                          TextButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text("Reject", style: TextStyle(color: Colors.red)),
                            onPressed: () => _updateStatus(context, booking.id, 'Rejected'),
                          ),
                          const SizedBox(width: 8),
                          
                          // APPROVE BUTTON
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text("Approve"),
                            onPressed: () => _updateStatus(context, booking.id, 'Approved'),
                          ),
                        ],
                      )
                    : null, // No buttons if already Approved/Rejected
              );
            },
          );
        },
      ),
    );
  }
}