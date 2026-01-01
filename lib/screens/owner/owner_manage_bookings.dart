import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../widgets/booking_card.dart';

class OwnerManageBookings extends StatelessWidget {
  const OwnerManageBookings({super.key});

  // Action: Approve or Reject
  void _updateStatus(BuildContext context, String bookingId, String newStatus) async {
    try {
      await DatabaseService().updateBookingStatus(bookingId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'Approved' ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text("Booking $newStatus successfully!"),
              ],
            ),
            backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = AuthService().getCurrentUserId();

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text(
          "Incoming Bookings",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange], // Professional Blue Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30.0),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: DatabaseService().getOwnerBookings(ownerId),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inbox_rounded, size: 60, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No pending requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "New bookings will appear here.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;

          // 3. List of Bookings
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return BookingCard(
                booking: booking,
                // Only show buttons if the status is 'Pending'
                actionButtons: booking.status == 'Pending' 
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            // REJECT BUTTON
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(context, booking.id, 'Rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // APPROVE BUTTON
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(context, booking.id, 'Approved'),
                                icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                                label: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null, // If not pending, return null (no buttons)
              );
            },
          );
        },
      ),
    );
  }
}