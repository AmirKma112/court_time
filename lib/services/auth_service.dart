import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =======================================================================
  // 1. GET CURRENT USER
  // =======================================================================
  User? get currentUser {
    return _auth.currentUser;
  }

  // Helper to just get the ID (we used this in other screens)
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // =======================================================================
  // 2. LOGIN
  // =======================================================================
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the error message (e.g. "User not found")
    } catch (e) {
      return 'An error occurred';
    }
  }

  // =======================================================================
  // 3. REGISTER
  // =======================================================================
  Future<String?> register({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred';
    }
  }

  // =======================================================================
  // 4. LOGOUT
  // =======================================================================
  Future<void> signOut() async {
    await _auth.signOut();
  }
}