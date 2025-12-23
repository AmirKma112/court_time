import 'package:court_time/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';

// 1. Import all your screens here
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_dashboard.dart';
import '../screens/home/court_list_screen.dart';
import '../screens/home/court_detail_screen.dart';
// import '../screens/admin/admin_manage_bookings.dart';
// import '../screens/admin/admin_manage_courts.dart';

// 2. Import Models (needed for passing arguments)
import '../models/court_model.dart';

// NOTE: Uncomment these imports once you create the files in the next steps
// import '../screens/booking/slot_selection_screen.dart';
// import '../screens/booking/booking_summary.dart';
// import '../screens/admin/admin_add_court_screen.dart';

class AppRoutes {
  // =========================================================================
  // ROUTE NAMES (Constants)
  // Use these strings instead of typing the path manually to avoid typos
  // =========================================================================
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String courtList = '/court-list';
  static const String courtDetail = '/court-detail';
  
  // Booking Routes
  static const String slotSelection = '/booking/slots';
  static const String bookingSummary = '/booking/summary';
  
  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminManageBookings = '/admin/bookings';
  static const String adminManageCourts = '/admin/courts';
  static const String adminAddCourt = '/admin/add-court';

  // =========================================================================
  // ROUTE GENERATOR
  // This function handles the navigation logic
  // =========================================================================
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      
      // --- Public & Auth ---
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // --- Main User Flow ---
      case home:
        return MaterialPageRoute(builder: (_) => const HomeDashboard());
      
      case courtList:
        // Extract the argument (e.g., "Badminton" or "Futsal")
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CourtListScreen(sportType: args),
        );

      case courtDetail:
        // Extract the argument (CourtModel object)
        final args = settings.arguments as CourtModel;
        return MaterialPageRoute(
          builder: (_) => CourtDetailScreen(court: args),
        );

      // --- Admin Flow ---
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      
      // case adminManageBookings:
      //   return MaterialPageRoute(builder: (_) => const AdminManageBookings());

      // case adminManageCourts:
      //   return MaterialPageRoute(builder: (_) => const AdminManageCourts());

      // --- Pending Screens (Uncomment when you create them) ---
      
      /*
      case slotSelection:
        final args = settings.arguments as CourtModel;
        return MaterialPageRoute(builder: (_) => SlotSelectionScreen(court: args));

      case adminAddCourt:
         // If args is null, it's "Add Mode", if args exists, it's "Edit Mode"
        final args = settings.arguments as CourtModel?; 
        return MaterialPageRoute(builder: (_) => AdminAddCourtScreen(courtToEdit: args));
      */

      // --- Default Error Route ---
      default:
        return _errorRoute();
    }
  }

  // Simple error page if navigation fails
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Page not found!")),
      );
    });
  }
}