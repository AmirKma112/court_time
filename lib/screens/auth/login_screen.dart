import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // To fetch user role
import '../../services/auth_service.dart';
import '../player/player_dashboard.dart'; // Redirect Player here
import '../owner/owner_dashboard.dart';   // Redirect Owner here
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Auth Login (Check email/password validity)
      String? result = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result == 'Success') {
        // 2. Fetch User Role from Firestore to decide where to go
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
              // Fallback if user doc is missing, assume player
               if (!mounted) return;
               setState(() => _isLoading = false);
               Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerDashboard()),
                );
            }
          } catch (e) {
            // Handle error fetching role
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching role: $e")),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? "Login failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sports_tennis, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                
                const Text(
                  "CourtTime+",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to your account",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 24),

                // LOGIN BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("LOGIN", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New here?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Create Account"),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}