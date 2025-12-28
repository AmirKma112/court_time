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
  Future<void> saveCourt(CourtModel court, {required bool isEditing}) async {
    if (isEditing) {
      await _courtsRef.doc(court.id).update(court.toMap());
    } else {
      await _courtsRef.add(court.toMap());
    }
  }

  // 2. DELETE COURT
  Future<void> deleteCourt(String courtId) async {
    await _courtsRef.doc(courtId).delete();
  }

  // 3. GET OWNER COURTS (Stream)
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

  // 4. GET COURT BY ID (New: Needed for Rescheduling)
  Future<CourtModel?> getCourtById(String courtId) async {
    try {
      final doc = await _courtsRef.doc(courtId).get();
      if (doc.exists) {
        return CourtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      // Handle error or return null
    }
    return null;
  }

  // =======================================================================
  // 🏸 PUBLIC COURT DATA (For Players)
  // =======================================================================

  // 5. GET ALL COURTS BY SPORT (Stream)
  Stream<List<CourtModel>> getCourts(String sportType) {
    return _courtsRef
        .where('type', isEqualTo: sportType)
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

  // 6. CREATE BOOKING (Player Action)
  Future<void> createBooking(BookingModel booking) async {
    await _bookingsRef.add(booking.toMap());
  }

  // 7. GET OWNER BOOKINGS (Owner Action)
  Stream<List<BookingModel>> getOwnerBookings(String ownerId) {
    return _bookingsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 8. UPDATE BOOKING STATUS (Owner Action - Approve/Reject)
  // Also used for Cancelling (Player Action)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).update({
      'status': newStatus,
    });
  }

  // 9. RESCHEDULE BOOKING (New: Update Date & Time)
  Future<void> rescheduleBooking(String bookingId, DateTime newDate, String newTime) async {
    await _bookingsRef.doc(bookingId).update({
      'bookingDate': Timestamp.fromDate(newDate),
      'timeSlot': newTime,
      'status': 'Pending', // Always reset to Pending so Owner can review the new time
    });
  }

  // 10. CHECK AVAILABILITY (Prevent Double Booking)
  Stream<List<String>> getBookedSlots(String courtId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _bookingsRef
        .where('courtId', isEqualTo: courtId) // 🔒 Critical Filter
        .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final List<String> bookedTimes = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? '';
        final time = data['timeSlot'] ?? '';

        // Only block slot if it is active (Pending, Approved, Confirmed)
        // Rejected/Cancelled/Completed slots become free again.
        if (status != 'Rejected' && status != 'Cancelled' && status != 'Completed') {
          bookedTimes.add(time);
        }
      }
      return bookedTimes;
    });
  }
}