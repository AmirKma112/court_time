import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_button.dart'; // Import CustomButton
import '../../../widgets/custom_input.dart';  // Import CustomInput

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Controller for email

  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 1. Fetch User Data
  void _fetchUserData() async {
    final user = AuthService().currentUser;
    if (user != null) {
      _userId = user.uid;
      // Pre-fill email from Auth
      _emailController.text = user.email ?? '';

      // Fetch extra details from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _phoneController.text = doc['phone'] ?? '';
        });
      }
    }
  }

  // 2. Update User Data
  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating profile: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- AVATAR SECTION ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 4),
                      boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Center(
                      child: Text(
                        (_emailController.text.isNotEmpty) ? _emailController.text[0].toUpperCase() : "p",
                        style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- EDIT FORM ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. Name Field using CustomInput
                    CustomInput(
                      label: "Full Name",
                      icon: Icons.person_outline,
                      controller: _nameController,
                      validator: (val) => val!.isEmpty ? "This field cannot be empty" : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Phone Field using CustomInput
                    CustomInput(
                      label: "Phone Number",
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val!.isEmpty ? "This field cannot be empty" : null,
                    ),
                    const SizedBox(height: 16),

                    // 3. Email Field (Read-only manual styling)
                    // We don't use CustomInput here because we want a specific "disabled" look
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      style: TextStyle(color: Colors.grey[600]),
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- SAVE BUTTON using CustomButton ---
            CustomButton(
              text: "SAVE CHANGES",
              onPressed: _updateProfile,
              isLoading: _isLoading,
              backgroundColor: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}