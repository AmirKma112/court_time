import 'package:cloud_firestore/cloud_firestore.dart';

class CourtModel {
  final String id;
  final String ownerId;       // Links this court to a specific Owner
  final String name;          // e.g., "Court A"
  final String type;          // "Badminton" or "Futsal"
  final double pricePerHour;  // e.g., 20.00
  final String location;      // e.g., "Hall B, Ground Floor"
  final String imageUrl;      // URL to image
  final String description;   // Brief description
  final List<String> amenities; // e.g., ["Air Cond", "Rubber Mat"]

  CourtModel({
    required this.id,
    required this.ownerId,    // Required in constructor
    required this.name,
    required this.type,
    required this.pricePerHour,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.amenities,
  });

  // =======================================================================
  // 1. Convert CourtModel to Map (For saving to Firestore)
  // =======================================================================
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId, // Save the owner's ID
      'name': name,
      'type': type,
      'pricePerHour': pricePerHour,
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
      'amenities': amenities,
    };
  }

  // =======================================================================
  // 2. Create CourtModel from Firestore Map (For reading data)
  // =======================================================================
  factory CourtModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CourtModel(
      id: documentId,
      ownerId: map['ownerId'] ?? '', // Load the owner's ID
      name: map['name'] ?? '',
      type: map['type'] ?? 'Badminton',
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? 'assets/images/placeholder.png',
      description: map['description'] ?? '',
      amenities: List<String>.from(map['amenities'] ?? []),
    );
  }
}