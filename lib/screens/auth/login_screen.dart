import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
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

    String? result = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result == 'Success') {
      String? uid = AuthService().getCurrentUserId();
      if (uid != null) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists) {
            String role = userDoc['role'] ?? 'player';

            if (!mounted) return;
            setState(() => _isLoading = false);

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
      // 1. DARKENED BACKGROUND so the white box is visible
      backgroundColor: Colors.grey[200], 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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

              // 2. THE BOX (Now with stronger shadow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // 2. STRONGER SHADOW (0.15 opacity instead of 0.05)
                      color: Colors.black.withOpacity(0.15), 
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // EMAIL INPUT
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

                      // PASSWORD INPUT
                      CustomInput(
                        label: "Password",
                        icon: Icons.lock,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (val) => val!.isEmpty ? "Please enter your password" : null,
                      ),

                      const SizedBox(height: 24),

                      // LOGIN BUTTON
                      CustomButton(
                        text: "LOGIN",
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // 3. REGISTER LINK
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
    );
  }
}