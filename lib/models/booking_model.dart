import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String courtId;
  final String courtName;
  final String ownerId;      // ⭐️ Ensure this exists
  final String userId;
  final String userName;     // ⭐️ Ensure this exists
  final DateTime bookingDate;
  final String timeSlot;
  final double totalPrice;
  final String status;       // 'Pending', 'Approved', etc.
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.ownerId,
    required this.userId,
    required this.userName,
    required this.bookingDate,
    required this.timeSlot,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  // 1. Convert to Map (For Saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'courtId': courtId,
      'courtName': courtName,
      'ownerId': ownerId,
      'userId': userId,
      'userName': userName,
      'bookingDate': Timestamp.fromDate(bookingDate), // Save as Timestamp
      'timeSlot': timeSlot,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // 2. Create from Map (For Reading from Firebase)
  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      courtId: map['courtId'] ?? '',
      courtName: map['courtName'] ?? 'Unknown Court',
      ownerId: map['ownerId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Player',
      
      // Handle Date Conversions safely
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      
      timeSlot: map['timeSlot'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}