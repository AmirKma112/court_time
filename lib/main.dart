import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'config/routes.dart';    
import 'config/theme.dart';     // 1. Import the new theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CourtTimeApp());
}

class CourtTimeApp extends StatelessWidget {
  const CourtTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourtTime+',
      debugShowCheckedModeBanner: false,

      // 2. Use the imported theme
      theme: AppTheme.lightTheme,

      // 3. Navigation Setup
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
    );
  }
}