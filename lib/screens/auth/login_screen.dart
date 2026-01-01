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
  bool _isPasswordVisible = false; // State to toggle password view

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
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. DECORATIVE HEADER
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Color.fromARGB(255, 152, 115, 255)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_tennis, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "CourtTime+",
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w800, 
                      color: Colors.white,
                      letterSpacing: 1.2
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Book your game, Play your way.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),

            // 2. FORM SECTION (Floating Card)
            Transform.translate(
              offset: const Offset(0, -40), // Pull up to overlap header
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Welcome Back",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                          ),
                        ),
                        const SizedBox(height: 24),

                        // EMAIL INPUT
                        CustomInput(
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Required";
                            if (!val.contains('@')) return "Invalid email";
                            return null;
                          },
                        ),

                        // PASSWORD INPUT WITH TOGGLE
                        CustomInput(
                          label: "Password",
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: !_isPasswordVisible, // Toggles obscureText
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),

                        // // FORGOT PASSWORD LINK (Optional addition)
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: TextButton(
                        //     onPressed: () {
                        //       // Add forgot password logic
                        //     },
                        //     child: const Text("Forgot Password?", style: TextStyle(fontSize: 12)),
                        //   ),
                        // ),

                        const SizedBox(height: 10),

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
              ),
            ),

            // 3. FOOTER
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
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
                    child: const Text("Register Now", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}