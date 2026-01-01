import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../../services/database_service.dart';
import '../../widgets/court_card.dart';
import 'court_detail_screen.dart';

class CourtListScreen extends StatelessWidget {
  final String sportType; // "Badminton" or "Futsal"

  const CourtListScreen({Key? key, required this.sportType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background for contrast
      appBar: AppBar(
        title: Text(
          "$sportType Courts",
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF448AFF)], // Modern Blue Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30.0),
            ),
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30.0),
          ),
        ),
      ),
      body: StreamBuilder<List<CourtModel>>(
        stream: DatabaseService().getCourts(sportType),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text("Error loading courts", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          // 3. Empty State (Improved UI)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    "No $sportType courts found.",
                    style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Check back later!",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // 4. Data Loaded State
          final courts = snapshot.data!;
          
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(), // Smoother scrolling feel
            itemCount: courts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final court = courts[index];
              
              return CourtCard(
                court: court,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtDetailScreen(court: court),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}