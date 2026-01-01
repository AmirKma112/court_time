import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../player/player_dashboard.dart';
import '../owner/owner_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // State variable for Role Selection
  String _selectedRole = 'player'; // Default role is Player

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Create Authentication Account
      String? result = await AuthService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result == 'Success') {
        // 2. Save User Details + ROLE to Firestore
        String? userId = AuthService().getCurrentUserId();
        if (userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'uid': userId,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole, // Saves 'player' or 'owner'
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        // 3. Smart Redirect based on Role
        if (_selectedRole == 'owner') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const OwnerDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PlayerDashboard()),
            (route) => false,
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? "Registration failed"), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define active colors based on role
    final Color activeColor = _selectedRole == 'owner' ? Colors.orange : Colors.blueAccent;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Darkened background for contrast
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: activeColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30.0),
            ),
          ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. HEADER TEXT (Outside the box)
              const Text(
                "Join CourtTime+",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Select your role to get started",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),

              // 2. THE WHITE BOX CONTAINER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
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
                      // --- ROLE SELECTION CARDS ---
                      Row(
                        children: [
                          // PLAYER CARD
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'player'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'player' ? Colors.blueAccent : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'player' ? Colors.blueAccent : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.person, size: 30, color: _selectedRole == 'player' ? Colors.white : Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Player",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == 'player' ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),

                          // OWNER CARD
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'owner'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'owner' ? Colors.orange : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'owner' ? Colors.orange : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.store, size: 30, color: _selectedRole == 'owner' ? Colors.white : Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Venue Owner",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == 'owner' ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 1. FULL NAME INPUT
                      CustomInput(
                        label: "Full Name",
                        icon: Icons.badge,
                        controller: _nameController,
                        validator: (val) => val!.isEmpty ? "Name is required" : null,
                      ),

                      // 2. PHONE INPUT
                      CustomInput(
                        label: "Phone Number",
                        icon: Icons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val!.isEmpty ? "Phone is required" : null,
                      ),

                      // 3. EMAIL INPUT
                      CustomInput(
                        label: "Email Address",
                        icon: Icons.email,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || !val.contains('@')) return "Invalid email";
                          return null;
                        },
                      ),

                      // 4. PASSWORD INPUT
                      CustomInput(
                        label: "Password",
                        icon: Icons.lock,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (val) => val!.length < 6 ? "Min 6 characters" : null,
                      ),

                      // 5. CONFIRM PASSWORD INPUT
                      CustomInput(
                        label: "Confirm Password",
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        validator: (val) {
                          if (val != _passwordController.text) return "Passwords do not match";
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // 6. REGISTER BUTTON (Dynamic Color)
                      CustomButton(
                        text: _selectedRole == 'owner' ? "REGISTER AS OWNER" : "REGISTER AS PLAYER",
                        isLoading: _isLoading,
                        backgroundColor: activeColor, // Changes based on role
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}