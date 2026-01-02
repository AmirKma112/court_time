import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:court_time/models/court_model.dart';
import 'package:court_time/services/database_service.dart';
import 'booking_summary.dart';

class SlotSelectionScreen extends StatefulWidget {
  final CourtModel court;
  final String? bookingId; // Optional: Reschedule Mode

  const SlotSelectionScreen({
    Key? key, 
    required this.court, 
    this.bookingId
  }) : super(key: key);

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  final List<DateTime> _nextDays = List.generate(
    7, (index) => DateTime.now().add(Duration(days: index))
  );

  final List<String> _allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", 
    "02:00 PM", "03:00 PM", "04:00 PM", 
    "05:00 PM", "08:00 PM", "09:00 PM"
  ];

  bool _isTimeSlotInPast(String timeSlot) {
    final now = DateTime.now();
    // If date is in future, time is not past
    if (_selectedDate.year > now.year || _selectedDate.month > now.month || _selectedDate.day > now.day) {
      return false; 
    }
    // If today, check time
    try {
      DateFormat format = DateFormat("hh:mm a"); 
      DateTime slotTime = format.parse(timeSlot);
      DateTime slotDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        slotTime.hour, slotTime.minute,
      );
      return slotDateTime.isBefore(now);
    } catch (e) {
      return false; 
    }
  }

  void _handleAction() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a time slot")));
      return;
    }

    // A. RESCHEDULE MODE
    if (widget.bookingId != null) {
      try {
        await DatabaseService().rescheduleBooking(
          widget.bookingId!, 
          _selectedDate, 
          _selectedTime!
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Rescheduled!")));
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    } 
    // B. NORMAL BOOKING MODE
    else {
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
  }

  @override
  Widget build(BuildContext context) {
    final isReschedule = widget.bookingId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
      appBar: AppBar(
        title: Text(
          isReschedule ? "Reschedule Booking" : "Select Slot",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. COURT INFO CARD
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.court.imageUrl,
                      width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(color: Colors.grey[200], width: 70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.court.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "RM ${widget.court.pricePerHour.toStringAsFixed(2)}/hour",
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. DATE SELECTION
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Select Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nextDays.length,
              itemBuilder: (context, index) {
                final date = _nextDays[index];
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                return GestureDetector(
                  onTap: () => setState(() { _selectedDate = date; _selectedTime = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 65,
                    margin: const EdgeInsets.only(right: 12, bottom: 5), // bottom margin for shadow
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? const LinearGradient(colors: [Color(0xFF2962FF), Color(0xFF448AFF)]) 
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: isSelected 
                          ? [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                          : [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date), 
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey, 
                            fontSize: 12, fontWeight: FontWeight.w500
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(), 
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87, 
                            fontWeight: FontWeight.bold, fontSize: 20
                          )
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 3. TIME SLOT LEGEND & GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // Legend
                Row(
                  children: [
                    _buildLegendDot(Colors.white, Colors.grey, "Available"),
                    const SizedBox(width: 8),
                    _buildLegendDot(const Color(0xFFFFF0F0), Colors.red[200]!, "Booked"),
                  ],
                )
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: DatabaseService().getBookedSlots(widget.court.id, _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading slots"));
                
                final bookedSlots = snapshot.data ?? [];

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    childAspectRatio: 2.2, 
                    crossAxisSpacing: 12, 
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _allTimeSlots.length,
                  itemBuilder: (context, index) {
                    final time = _allTimeSlots[index];
                    final isBooked = bookedSlots.contains(time);
                    final isPast = _isTimeSlotInPast(time);
                    final isSelected = _selectedTime == time;

                    return GestureDetector(
                      onTap: (isBooked || isPast) 
                          ? null 
                          : () => setState(() => _selectedTime = isSelected ? null : time),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isBooked 
                              ? const Color(0xFFFFF0F0) // Light Red for Booked
                              : (isPast ? Colors.grey[100] : (isSelected ? Colors.blueAccent : Colors.white)),
                          gradient: isSelected 
                              ? const LinearGradient(colors: [Color(0xFF2962FF), Color(0xFF448AFF)]) 
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBooked 
                                ? Colors.transparent 
                                : (isSelected ? Colors.transparent : (isPast ? Colors.transparent : Colors.grey.shade300)),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isBooked ? "Booked" : (isPast ? "Closed" : time),
                          style: TextStyle(
                            color: isBooked 
                                ? Colors.red[300] 
                                : (isPast ? Colors.grey : (isSelected ? Colors.white : Colors.black87)),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            decoration: (isBooked || isPast) ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 4. BOTTOM ACTION BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _selectedTime == null ? null : _handleAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReschedule ? Colors.orange : Colors.blueAccent,
                    elevation: 0,
                  ),
                  child: Text(
                    isReschedule ? "RESCHEDULE" : "CONTINUE",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the Legend (Small dots next to "Select Time")
  Widget _buildLegendDot(Color color, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}