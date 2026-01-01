import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/routes.dart'; // Import your routes

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2. Check Login State instead of just waiting
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- NEW LOGIC FOR PERSISTENT LOGIN ---
  _checkAuthAndNavigate() async {
    // A. Wait for the animation/branding (at least 2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // B. Check if a user is already logged in via Firebase
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (currentUser != null) {
      // --- USER IS LOGGED IN ---
      try {
        // C. Fetch their Role from Firestore to know which dashboard to open
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (mounted) {
          if (userDoc.exists) {
            String role = userDoc['role'] ?? 'player';

            // D. Redirect based on Role
            if (role == 'owner') {
              Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.playerDashboard);
            }
          } else {
            // Edge case: User exists in Auth but not in Database -> Go to Login
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        }
      } catch (e) {
        // If internet error or DB error, fall back to Login
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      // --- USER IS NOT LOGGED IN ---
      // E. Go to Login Screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. The Spinning Loader (Outer Ring)
                          const SizedBox(
                            width: 120, // Slightly larger than the logo container (70 + 20*2 = 110)
                            height: 120,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3, 
                            ),
                          ),
                          // 2. The Logo Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            width: 110, // Fixed width to ensure perfect centering
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: const Image(
                              image: AssetImage('images/logo1.png'),
                              color: Colors.white,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "CourtTime+",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(offset: Offset(0, 4), blurRadius: 10.0, color: Colors.black26),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: const Text(
                          "Book your game. Pay at the venue.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}