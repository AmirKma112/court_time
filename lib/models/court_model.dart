import 'package:cloud_firestore/cloud_firestore.dart';

class CourtModel {
  final String id;
  final String name;          // e.g., "Court A", "Court 1"
  final String type;          // "Badminton" or "Futsal"
  final double pricePerHour;  // e.g., 20.00
  final String location;      // e.g., "Hall B, Ground Floor"
  final String imageUrl;      // URL to image or asset path
  final String description;   // Brief description of the court
  final List<String> amenities; // e.g., ["Air Cond", "Rubber Mat"]

  CourtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerHour,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.amenities,
  });

  // 1. Convert CourtModel to Map (useful if you create an Admin panel later)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'pricePerHour': pricePerHour,
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
      'amenities': amenities,
    };
  }

  // 2. Create CourtModel from Firestore Map (Used in Court List Screen)
  factory CourtModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CourtModel(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Badminton',
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? 'assets/images/placeholder.png', // Fallback image
      description: map['description'] ?? '',
      // Safely convert a dynamic list from Firebase to List<String>
      amenities: List<String>.from(map['amenities'] ?? []),
    );
  }
}