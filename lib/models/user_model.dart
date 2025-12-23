import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;           // The unique ID from Firebase Auth
  final String email;         // User's email address
  final String name;          // User's full name
  final String phone;         // Contact number (Important for bookings)
  final String role;          // CRITICAL: 'player' or 'owner'
  final DateTime createdAt;   // When the account was created

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  // =======================================================================
  // 1. Convert UserModel to Map (For saving to Firestore)
  // =======================================================================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role, // This saves the selection (Player vs Owner)
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // =======================================================================
  // 2. Create UserModel from Firestore Map (For reading user data)
  // =======================================================================
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      // Default to 'player' if role is missing for safety
      role: map['role'] ?? 'player', 
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}