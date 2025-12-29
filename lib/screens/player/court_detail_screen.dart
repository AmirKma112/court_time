import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../player/booking/slot_selection_screen.dart';

class CourtDetailScreen extends StatelessWidget {
  final CourtModel court;

  const CourtDetailScreen({Key? key, required this.court}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. Top Section: Image
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image (Full Width)
                  Stack(
                    children: [
                      Image.network(
                        court.imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                      // Back Button overlay
                      Positioned(
                        top: 40,
                        left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                court.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              "RM ${court.pricePerHour.toStringAsFixed(2)}/hr",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 18),
                            const SizedBox(width: 4),
                            Expanded( 
                              child: Text(
                              court.location,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis, // Adds "..." at the end
                              maxLines: 2, // Only show 1 line (change to 2 if you want wrapping)
                            ),
                          )
                           
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        const Divider(),
                        
                        // Description
                        const Text(
                          "Description",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          court.description.isNotEmpty 
                              ? court.description 
                              : "No description available for this court.",
                          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),

                        // Amenities Section
                        const Text(
                          "Amenities",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        court.amenities.isNotEmpty
                            ? Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: court.amenities.map((amenity) {
                                  return Chip(
                                    label: Text(amenity),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: Colors.blueAccent),
                                    avatar: const Icon(Icons.check, size: 16, color: Colors.blueAccent),
                                  );
                                }).toList(),
                              )
                            : const Text("No specific amenities listed.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Bottom Section: Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Navigate to Slot Selection
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SlotSelectionScreen(court: court),
                      ),
                    );
                  },
                  child: const Text(
                    "BOOK NOW", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}