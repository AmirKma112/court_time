import 'package:flutter/material.dart';
import 'package:court_time/screens/splash/splash_screen.dart';

// --- Auth Screens ---
import 'package:court_time/screens/auth/login_screen.dart';
import 'package:court_time/screens/auth/register_screen.dart';

// --- Player Screens ---
import 'package:court_time/screens/player/player_dashboard.dart';
import 'package:court_time/screens/player/profile/my_bookings_screen.dart';

// --- Owner Screens ---
import 'package:court_time/screens/owner/owner_dashboard.dart';
import 'package:court_time/screens/owner/owner_manage_bookings.dart';
import 'package:court_time/screens/owner/owner_manage_courts.dart';
import 'package:court_time/screens/owner/owner_add_court.dart';

class AppRoutes {
  // --- Route Name Constants ---
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  // Player
  static const String playerDashboard = '/player/dashboard';
  static const String playerMyBookings = '/player/my_bookings';

  // Owner
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerManageBookings = '/owner/manage_bookings';
  static const String ownerManageCourts = '/owner/manage_courts';
  static const String ownerAddCourt = '/owner/add_court';

  // --- Route Map ---
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      
      // Player
      playerDashboard: (context) => const PlayerDashboard(),
      playerMyBookings: (context) => const MyBookingsScreen(),
      
      // Owner
      ownerDashboard: (context) => const OwnerDashboard(),
      ownerManageBookings: (context) => const OwnerManageBookings(),
      ownerManageCourts: (context) => const OwnerManageCourts(),
      
      // Note: This route is for "Adding" a court (no arguments). 
      // To "Edit", you should use MaterialPageRoute to pass the court object.
      ownerAddCourt: (context) => const OwnerAddCourt(),
    };
  }
}