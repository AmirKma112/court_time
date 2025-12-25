import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:court_time/models/court_model.dart';
import 'package:court_time/models/booking_model.dart';
import 'package:court_time/services/auth_service.dart';
import 'package:court_time/services/database_service.dart';
import 'package:court_time/screens/player/profile/my_bookings_screen.dart';

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
      ownerId: widget.court.ownerId, // 🔒 Vital for Owner visibility
      userId: user.uid,
      userName: user.displayName ?? "Player", // Or fetch from profile
      bookingDate: widget.date,
      timeSlot: widget.timeSlot,
      totalPrice: widget.court.pricePerHour, // Assuming 1 hour for now
      status: 'Pending', // Default status
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
    // Format Date for display (e.g., "Monday, 25 Oct 2025")
    final dateString = DateFormat('EEEE, d MMM y').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Court Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.court.imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(color: Colors.grey, width: 60),
                  ),
                ),
                title: Text(widget.court.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.court.location),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Booking Summary Details
            const Text("Booking Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.calendar_today, "Date", dateString),
            _buildDetailRow(Icons.access_time, "Time", widget.timeSlot),
            _buildDetailRow(Icons.sports_tennis, "Sport", widget.court.type),
            
            const Divider(height: 30),

            // 3. Price Calculation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "RM ${widget.court.pricePerHour.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 4. Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM BOOKING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// ============================================================================
// SIMPLE SUCCESS SCREEN
// ============================================================================
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Booking Successful!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your booking is pending approval from the venue owner. check 'My Bookings' for updates.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // Button: Go to My Bookings
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: () {
                    // Navigate to My Bookings and remove all previous booking screens from stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                      (route) => route.isFirst, // Keep only the dashboard/main wrapper
                    );
                  },
                  child: const Text("VIEW MY BOOKINGS"),
                ),
              ),
              
              TextButton(
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                }, 
                child: const Text("Back to Home")
              )
            ],
          ),
        ),
      ),
    );
  }
}