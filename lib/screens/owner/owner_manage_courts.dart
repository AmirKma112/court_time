import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/court_model.dart';
import 'owner_add_court.dart';

class OwnerManageCourts extends StatelessWidget {
  const OwnerManageCourts({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentOwnerId = AuthService().getCurrentUserId();

    if (currentOwnerId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text(
          "My Courts",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // Owner Orange Theme
              colors: [Colors.orange, Colors.deepOrange], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add New Court", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OwnerAddCourt()),
          );
        },
      ),
      
      body: StreamBuilder<List<CourtModel>>(
        stream: DatabaseService().getOwnerCourts(currentOwnerId),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          // Error
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stadium_rounded, size: 60, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No courts added yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap '+ Add New Court' to get started.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final courts = snapshot.data!;
          
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Bottom padding for FAB
            itemCount: courts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final court = courts[index];
              
              // Custom Court Card
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    // Edit Mode
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerAddCourt(courtToEdit: court),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 1. Image Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                court.imageUrl,
                                width: 80, height: 80, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 80, height: 80, color: Colors.grey[200], 
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey)
                                ),
                              ),
                              // Sport Type Badge overlay
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  color: Colors.black.withOpacity(0.6),
                                  child: Text(
                                    court.type,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // 2. Info Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                court.location,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "RM ${court.pricePerHour.toStringAsFixed(2)}/hour",
                                      style: const TextStyle(
                                        color: Colors.deepOrange, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 3. Actions (Edit Icon implies functionality, Delete is explicit)
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                              tooltip: "Edit Court",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OwnerAddCourt(courtToEdit: court),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: "Delete Court",
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Court?"),
                                    content: Text("Are you sure you want to delete '${court.name}'?"),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    actions: [
                                      TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx, false)),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}