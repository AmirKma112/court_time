import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart'; // Assuming you create this model later

class DatabaseService {
  // Reference to the 'bookings' collection in Firestore
  final CollectionReference _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');
      
  // Reference to the 'courts' collection
  final CollectionReference _courtsRef =
      FirebaseFirestore.instance.collection('courts');

  // =======================================================================
  // CREATE: Add a new booking to Firestore
  // =======================================================================
  Future<void> createBooking(BookingModel booking) async {
    try {
      // We use .set() with the specific booking ID so we can easily reference it later
      await _bookingsRef.doc(booking.id).set(booking.toMap());
      print("Booking successfully added!");
    } catch (e) {
      print("Error creating booking: $e");
      throw e; // Rethrow to handle in the UI (e.g., show error snackbar)
    }
  }

  // =======================================================================
  // READ: Get all bookings for a specific user (My Bookings Page)
  // =======================================================================
  Stream<List<BookingModel>> getUserBookings(String userId) {
    // Queries Firestore for documents where 'userId' matches the current user
    return _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true) // Show newest bookings first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // =======================================================================
  // READ: Get list of available courts (Court List Page)
  // =======================================================================
  Stream<List<CourtModel>> getCourts(String sportType) {
    return _courtsRef
        .where('type', isEqualTo: sportType) // Filter by "Badminton" or "Futsal"
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Note: You will need a CourtModel.fromMap similar to BookingModel
        return CourtModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // =======================================================================
  // UPDATE: Cancel a booking (Change status to 'Cancelled')
  // =======================================================================
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'status': 'Cancelled',
      });
      print("Booking cancelled successfully");
    } catch (e) {
      print("Error cancelling booking: $e");
      throw e;
    }
  }
  
  // =======================================================================
  // DELETE: (Optional) Permanently remove a booking
  // =======================================================================
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _bookingsRef.doc(bookingId).delete();
    } catch (e) {
      print("Error deleting booking: $e");
    }
  }

  // =======================================================================
  // owner_manage_court
  // =======================================================================
  // Fetch Courts specific to ONE Owner
  Stream<List<CourtModel>> getOwnerCourts(String ownerId) {
    return _courtsRef
        .where('ownerId', isEqualTo: ownerId) // 🔒 The Security Filter
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Delete Court
  Future<void> deleteCourt(String courtId) async {
    await _courtsRef.doc(courtId).delete();
  }

  // Save Court (Create or Update)
  Future<void> saveCourt(CourtModel court, {required bool isEditing}) async {
    if (isEditing) {
      // UPDATE existing document
      await _courtsRef.doc(court.id).update(court.toMap());
    } else {
      // CREATE new document
      // Note: We don't manually set ID here, Firestore does it. 
      // But our Model expects an ID. 
      // Logic: Add to collection, then get the reference back.
      DocumentReference docRef = await _courtsRef.add(court.toMap());
      
      // Optional: If you want to store the ID inside the document fields too
      // await docRef.update({'id': docRef.id}); 
    }
  }
}