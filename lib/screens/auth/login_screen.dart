import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';  // Import the Input Widget
import '../../widgets/custom_button.dart'; // Import the Button Widget
import '../player/player_dashboard.dart';
import '../owner/owner_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Auth Login
    String? result = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result == 'Success') {
      // 2. Fetch User Role
      String? uid = AuthService().getCurrentUserId();
      if (uid != null) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists) {
            String role = userDoc['role'] ?? 'player'; // Default to player

            if (!mounted) return;
            setState(() => _isLoading = false);

            // 3. Redirect based on Role
            if (role == 'owner') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OwnerDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PlayerDashboard()),
              );
            }
          } else {
             // Fallback: If no user doc exists, assume player
             if (!mounted) return;
             setState(() => _isLoading = false);
             Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PlayerDashboard()),
              );
          }
        } catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching role: $e")),
          );
        }
      }
    } else {
      // Login Failed
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? "Login failed"), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO & TITLE
                const Icon(Icons.sports_tennis, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  "CourtTime+",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.blueAccent
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome back! Please login.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 40),

                // 2. EMAIL INPUT
                CustomInput(
                  label: "Email Address",
                  icon: Icons.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Please enter your email";
                    if (!val.contains('@')) return "Invalid email address";
                    return null;
                  },
                ),

                // 3. PASSWORD INPUT
                CustomInput(
                  label: "Password",
                  icon: Icons.lock,
                  controller: _passwordController,
                  isPassword: true,
                  validator: (val) => val!.isEmpty ? "Please enter your password" : null,
                ),

                const SizedBox(height: 24),

                // 4. LOGIN BUTTON (Using CustomButton)
                CustomButton(
                  text: "LOGIN",
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                
                const SizedBox(height: 24),

                // 5. REGISTER LINK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}