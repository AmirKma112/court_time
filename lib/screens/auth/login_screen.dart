import 'package:court_time/owner/owner_dashboard.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_dashboard.dart';      // Redirect regular users here    // Redirect admin here
import 'register_screen.dart';             // Redirect to sign up

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to retrieve text from input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Key for form validation
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  void _handleLogin() async {
    // 1. Validate the form (Check if empty)
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 2. Call Firebase Auth Service
      String? result = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result == 'Success') {
        if (!mounted) return;

        // 3. ADMIN CHECK: Route based on email
        if (_emailController.text.trim() == 'admin@courttime.com') {
          // Go to Admin Panel
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          // Go to User Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeDashboard()),
          );
        }
        
      } else {
        // 4. Show error message (e.g., Wrong password)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? "Login failed"), 
            backgroundColor: Colors.red
          ),
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
                // Icon / Logo
                const Icon(Icons.lock_person, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                
                const Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    if (!value.contains('@')) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // Hide password text
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text("LOGIN", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Register"),
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