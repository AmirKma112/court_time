import 'package:flutter/material.dart';
import '../profile/my_bookings_screen.dart';

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
              // Animated Scale or just a large Icon
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Booking Successful!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your booking is pending approval from owner. Check 'My Bookings' for updates.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              
              // Button: Go to My Bookings
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Navigate to My Bookings and remove previous booking screens
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                      (route) => route.isFirst, // Keep only the dashboard/main wrapper
                    );
                  },
                  child: const Text("VIEW MY BOOKINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                }, 
                child: const Text("Back to Home", style: TextStyle(color: Colors.grey))
              )
            ],
          ),
        ),
      ),
    );
  }
}