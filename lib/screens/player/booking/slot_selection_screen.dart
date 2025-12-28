import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:court_time/models/court_model.dart';
import 'package:court_time/services/database_service.dart';
import 'booking_summary.dart';

class SlotSelectionScreen extends StatefulWidget {
  final CourtModel court;

  const SlotSelectionScreen({Key? key, required this.court}) : super(key: key);

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  final List<DateTime> _nextDays = List.generate(
    7, 
    (index) => DateTime.now().add(Duration(days: index))
  );

  final List<String> _allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", 
    "02:00 PM", "03:00 PM", "04:00 PM", 
    "05:00 PM", "08:00 PM", "09:00 PM"
  ];

  void _proceedToSummary() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryScreen(
          court: widget.court,
          date: _selectedDate,
          timeSlot: _selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Slot"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.court.imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(color: Colors.grey[200], width: 60),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.court.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text("RM ${widget.court.pricePerHour}/hour"),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Date Selection
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Select Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nextDays.length,
              itemBuilder: (context, index) {
                final date = _nextDays[index];
                final isSelected = 
                    date.day == _selectedDate.day && 
                    date.month == _selectedDate.month;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedTime = null; // Reset time when date changes
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade300
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date), 
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Time Selection (Dynamic Stream)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Select Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: StreamBuilder<List<String>>(
              // It listens to the database for occupied slots on this specific day
              stream: DatabaseService().getBookedSlots(widget.court.id, _selectedDate),
              builder: (context, snapshot) {
                
                // Determine which slots are taken
                final bookedSlots = snapshot.data ?? [];

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allTimeSlots.length,
                  itemBuilder: (context, index) {
                    final time = _allTimeSlots[index];
                    
                    // Logic: Is this slot already booked?
                    final isBooked = bookedSlots.contains(time);
                    final isSelected = _selectedTime == time;

                    return ChoiceChip(
                      label: Text(isBooked ? "Booked" : time),
                      // Grey out if booked, Blue if selected, White if available
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: isBooked ? Colors.grey[300] : Colors.grey[100],
                      labelStyle: TextStyle(
                        // Grey text if booked
                        color: isBooked 
                            ? Colors.grey 
                            : (isSelected ? Colors.white : Colors.black),
                        fontSize: 12,
                        decoration: isBooked ? TextDecoration.lineThrough : null,
                      ),
                      // Disable tap if booked
                      onSelected: isBooked ? null : (selected) {
                        setState(() => _selectedTime = selected ? time : null);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 4. Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white, 
              boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)]
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedTime == null ? null : _proceedToSummary,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("CONTINUE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}