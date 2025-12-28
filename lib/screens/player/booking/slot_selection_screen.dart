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

  // 🕒 HELPER: Check if a time slot is in the past
  bool _isTimeSlotInPast(String timeSlot) {
    final now = DateTime.now();
    
    // 1. If selected date is in the future (tomorrow+), the slot is NOT in the past.
    if (_selectedDate.year > now.year || 
        _selectedDate.month > now.month || 
        _selectedDate.day > now.day) {
      return false; 
    }

    // 2. If selected date is TODAY, we must check the hour.
    try {
      // Parse "09:00 AM" to get the hour
      // We assume the format is strictly "hh:mm a"
      DateFormat format = DateFormat("hh:mm a"); 
      DateTime slotTime = format.parse(timeSlot);

      // Create a full DateTime object for this slot today
      DateTime slotDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slotTime.hour,
        slotTime.minute,
      );

      // Return true if the slot is before right now
      return slotDateTime.isBefore(now);
    } catch (e) {
      return false; // Safety fallback
    }
  }

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
                      _selectedTime = null; 
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

          // 3. Time Selection
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Select Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: DatabaseService().getBookedSlots(widget.court.id, _selectedDate),
              builder: (context, snapshot) {
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

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
                    
                    // 🛑 LOGIC UPDATE: Check both Database AND Time
                    final isBooked = bookedSlots.contains(time);
                    final isPast = _isTimeSlotInPast(time);
                    
                    final isDisabled = isBooked || isPast;
                    final isSelected = _selectedTime == time;

                    return ChoiceChip(
                      label: Text(
                        isBooked ? "Booked" : (isPast ? "Expired" : time),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      
                      // Dark Grey for Booked, Light Grey for Past, White for Available
                      backgroundColor: isBooked 
                          ? Colors.grey[400] 
                          : (isPast ? Colors.grey[200] : Colors.grey[100]),
                      
                      labelStyle: TextStyle(
                        color: isDisabled 
                            ? Colors.grey 
                            : (isSelected ? Colors.white : Colors.black),
                        fontSize: 12,
                        decoration: isDisabled ? TextDecoration.lineThrough : null,
                      ),
                      
                      // Disable tap if booked OR past
                      onSelected: isDisabled ? null : (selected) {
                        setState(() => _selectedTime = selected ? time : null);
                      },
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
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