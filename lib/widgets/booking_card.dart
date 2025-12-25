import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  // This optional parameter allows the Owner screen to add Buttons here
  final Widget? trailing; 

  const BookingCard({
    Key? key,
    required this.booking,
    this.trailing,
  }) : super(key: key);

  // Helper to determine badge color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Completed': return Colors.blueGrey;
      default: return Colors.orange; // For 'Pending'
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE: Court Name & Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.courtName,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11, 
                          color: statusColor, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),

                // RIGHT SIDE: Date & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.bookingDate.toString().split(' ')[0], // Format: YYYY-MM-DD
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.timeSlot,
                      style: const TextStyle(
                        color: Colors.blueAccent, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // OPTIONAL ACTION BUTTONS (For Owner)
            // Only renders if 'trailing' is passed
            if (trailing != null) ...[
              const Divider(height: 24),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}