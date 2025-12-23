import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class OwnerAddCourt extends StatefulWidget {
  // If this is null, we are in "Add Mode". If provided, we are in "Edit Mode".
  final CourtModel? courtToEdit;

  const OwnerAddCourt({super.key, this.courtToEdit});

  @override
  State<OwnerAddCourt> createState() => _OwnerAddCourtState();
}

class _OwnerAddCourtState extends State<OwnerAddCourt> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();

  // Dropdown State
  String _selectedType = 'Badminton';

  // Amenities State
  final List<String> _availableAmenities = ['Air Cond', 'WiFi', 'Parking', 'Showers', 'Equipment Rent', 'Locker'];
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill data if we are Editing
    if (widget.courtToEdit != null) {
      _nameController.text = widget.courtToEdit!.name;
      _priceController.text = widget.courtToEdit!.pricePerHour.toString();
      _locationController.text = widget.courtToEdit!.location;
      _descController.text = widget.courtToEdit!.description;
      _imageController.text = widget.courtToEdit!.imageUrl;
      _selectedType = widget.courtToEdit!.type;
      _selectedAmenities.addAll(widget.courtToEdit!.amenities);
    }
  }

  void _saveCourt() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Get Current Owner ID (Crucial for Data Isolation)
      String? ownerId = AuthService().getCurrentUserId();
      if (ownerId == null) {
        // Handle error: User logged out
        setState(() => _isLoading = false);
        return;
      }

      // 2. Prepare Data Object
      // Use existing ID if editing, or create new logic in Service
      final newCourt = CourtModel(
        id: widget.courtToEdit?.id ?? '', // Service will handle ID generation if empty
        ownerId: ownerId, // 🔒 Link to THIS owner
        name: _nameController.text.trim(),
        type: _selectedType,
        pricePerHour: double.parse(_priceController.text.trim()),
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _imageController.text.trim().isEmpty 
            ? 'https://via.placeholder.com/150' // Fallback image
            : _imageController.text.trim(),
        amenities: _selectedAmenities,
      );

      // 3. Save to Firebase
      try {
        await DatabaseService().saveCourt(newCourt, isEditing: widget.courtToEdit != null);
        
        if (!mounted) return;
        Navigator.pop(context); // Go back to List
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Court Saved Successfully!")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.courtToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Court" : "Add New Court"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Court Name (e.g., Hall A)"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 2. Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Sport Type"),
                items: ['Badminton', 'Futsal']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // 3. Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Price Per Hour (RM)", prefixText: "RM "),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (double.tryParse(val) == null) return "Invalid number";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location / Floor"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 5. Image URL Field (Simplest way for assignment)
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL (Optional)",
                  hintText: "Paste a link to an image",
                  suffixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Amenities (Filter Chips)
              const Text("Select Amenities:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 7. Description Field
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description / Rules"),
              ),
              const SizedBox(height: 30),

              // SAVE BUTTON
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveCourt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.save),
                label: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("SAVE COURT", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}