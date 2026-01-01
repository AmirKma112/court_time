import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/court_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import 'booking_success.dart'; // Import the new file here

class BookingSummaryScreen extends StatefulWidget {
  final CourtModel court;
  final DateTime date;
  final String timeSlot;

  const BookingSummaryScreen({
    super.key,
    required this.court,
    required this.date,
    required this.timeSlot,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isLoading = false;

  void _confirmBooking() async {
    setState(() => _isLoading = true);

    // 1. Get User Info
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: You are not logged in.")),
      );
      return;
    }

    // 2. Create Booking Object
    final newBooking = BookingModel(
      id: '', // Firestore will generate this
      courtId: widget.court.id,
      courtName: widget.court.name,
      ownerId: widget.court.ownerId,
      userId: user.uid,
      userName: user.displayName ?? "Player",
      bookingDate: widget.date,
      timeSlot: widget.timeSlot,
      totalPrice: widget.court.pricePerHour, 
      status: 'Pending', 
      createdAt: DateTime.now(),
    );

    // 3. Save to Database
    try {
      await DatabaseService().createBooking(newBooking);

      if (!mounted) return;

      // 4. Navigate to Success Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingSuccessScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format Date for display
    final dateString = DateFormat('EEEE, d MMM y').format(widget.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30.0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Court Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.court.imageUrl,
                      width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(color: Colors.grey[200], width: 70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.court.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(widget.court.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Booking Summary Details
            const Text("Booking Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                   _buildDetailRow(Icons.calendar_today, "Date", dateString),
                   const Divider(height: 20),
                   _buildDetailRow(Icons.access_time, "Time", widget.timeSlot),
                   const Divider(height: 20),
                   _buildDetailRow(Icons.sports_tennis, "Sport", widget.court.type),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. Price Calculation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Price", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(
                    "RM ${widget.court.pricePerHour.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 4. Confirm Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  elevation: 5,
                  shadowColor: Colors.blueAccent.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM BOOKING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
      ],
    );
  }
}