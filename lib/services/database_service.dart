import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/court_model.dart';
import '../models/booking_model.dart';

class DatabaseService {
  // Collection References
  final CollectionReference _courtsRef =
      FirebaseFirestore.instance.collection('courts');
  final CollectionReference _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');

  // =======================================================================
  // 🏢 COURT MANAGEMENT (For Venue Owners)
  // =======================================================================

  // 1. SAVE COURT (Create or Update)
  // Logic: If isEditing is true, we update. If false, we add new.
  Future<void> saveCourt(CourtModel court, {required bool isEditing}) async {
    if (isEditing) {
      await _courtsRef.doc(court.id).update(court.toMap());
    } else {
      // Add to Firestore and let it generate a unique ID
      await _courtsRef.add(court.toMap());
    }
  }

  // 2. DELETE COURT
  Future<void> deleteCourt(String courtId) async {
    await _courtsRef.doc(courtId).delete();
  }

  // 3. GET OWNER COURTS (Stream)
  // Security: Only fetches courts belonging to the specific ownerId
  Stream<List<CourtModel>> getOwnerCourts(String ownerId) {
    return _courtsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // =======================================================================
  // 🏸 PUBLIC COURT DATA (For Players)
  // =======================================================================

  // 4. GET ALL COURTS BY SPORT (Stream)
  // Used in CourtListScreen to show all available courts
  Stream<List<CourtModel>> getCourts(String sportType) {
    return _courtsRef
        .where('type', isEqualTo: sportType) // Filter by 'Badminton' or 'Futsal'
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // =======================================================================
  // 📅 BOOKING MANAGEMENT
  // =======================================================================

  // 5. CREATE BOOKING (Player Action)
  Future<void> createBooking(BookingModel booking) async {
    await _bookingsRef.add(booking.toMap());
  }

  // 6. GET OWNER BOOKINGS (Owner Action)
  // Fetches bookings only for courts owned by this specific owner
  Stream<List<BookingModel>> getOwnerBookings(String ownerId) {
    return _bookingsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true) // Newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 7. UPDATE BOOKING STATUS (Owner Action)
  // Used to Approve or Reject a booking
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).update({
      'status': newStatus,
    });
  }

  // 8. GET PLAYER BOOKINGS (Optional Helper)
  // If you want to clean up MyBookingsScreen later, you can use this
  Stream<List<BookingModel>> getPlayerBookings(String userId) {
    return _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}