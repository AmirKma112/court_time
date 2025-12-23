import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/court_model.dart';
import 'owner_add_court.dart'; // We create this next

class OwnerManageCourts extends StatelessWidget {
  const OwnerManageCourts({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the Current Owner's ID
    // This ensures we only fetch THEIR courts
    final String? currentOwnerId = AuthService().getCurrentUserId();

    if (currentOwnerId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courts"),
        backgroundColor: Colors.blueGrey,
      ),
      // Add Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add),
        onPressed: () {
          // Navigate to Add Court Screen (Mode: Create)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OwnerAddCourt()),
          );
        },
      ),
      body: StreamBuilder<List<CourtModel>>(
        // 2. The Filtered Query
        // We call the specific function for owners
        stream: DatabaseService().getOwnerCourts(currentOwnerId),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "You haven't added any courts yet.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text("Tap the + button to add one."),
                ],
              ),
            );
          }

          // 3. List of Courts
          final courts = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  // Court Image Thumbnail
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      court.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60, height: 60, color: Colors.grey[300], 
                        child: const Icon(Icons.broken_image, size: 20)
                      ),
                    ),
                  ),
                  // Court Info
                  title: Text(
                    court.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(court.type, style: const TextStyle(color: Colors.blueAccent)),
                      Text("RM ${court.pricePerHour.toStringAsFixed(2)}/hr"),
                    ],
                  ),
                  // Delete Button
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      // Confirm Delete Dialog
                      bool confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Court?"),
                          content: const Text("This action cannot be undone."),
                          actions: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            TextButton(
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirm) {
                        await DatabaseService().deleteCourt(court.id);
                        if(context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Court deleted"))
                          );
                        }
                      }
                    },
                  ),
                  // Edit Action
                  onTap: () {
                    // Navigate to Add Court Screen (Mode: Edit)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerAddCourt(courtToEdit: court),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}