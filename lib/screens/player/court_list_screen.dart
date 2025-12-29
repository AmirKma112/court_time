import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../../services/database_service.dart';
import '../../widgets/court_card.dart'; // We will create this next
import 'court_detail_screen.dart'; // You will create this later

class CourtListScreen extends StatelessWidget {
  final String sportType; // "Badminton" or "Futsal"

  const CourtListScreen({Key? key, required this.sportType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$sportType Courts"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<CourtModel>>(
        // Call the function made in DatabaseService
        stream: DatabaseService().getCourts(sportType),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No courts available for this category."));
          }

          // 4. Data Loaded State
          final courts = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              
              // We pass the data to our custom widget
              return CourtCard(
                court: court,
                onTap: () {
                  // Navigate to Detail Screen
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