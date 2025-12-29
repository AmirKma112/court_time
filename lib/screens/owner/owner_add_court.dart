import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For uploading
import '../../models/court_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart'; // Assuming you have this
import '../../widgets/custom_input.dart';  // Assuming you have this

class OwnerAddCourt extends StatefulWidget {
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
  
  // Image State
  File? _pickedImageFile;        // The new image selected from device
  String? _existingImageUrl;     // The URL if editing an existing court

  // Dropdown & Amenities
  String _selectedType = 'Badminton';
  final List<String> _availableAmenities = ['Air Cond', 'WiFi', 'Parking', 'Showers', 'Equipment Rent', 'Locker'];
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill data if Editing
    if (widget.courtToEdit != null) {
      _nameController.text = widget.courtToEdit!.name;
      _priceController.text = widget.courtToEdit!.pricePerHour.toString();
      _locationController.text = widget.courtToEdit!.location;
      _descController.text = widget.courtToEdit!.description;
      _selectedType = widget.courtToEdit!.type;
      _selectedAmenities.addAll(widget.courtToEdit!.amenities);
      _existingImageUrl = widget.courtToEdit!.imageUrl;
    }
  }

  // 1. FUNCTION TO PICK IMAGE
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery, // Change to ImageSource.camera to take a photo
      imageQuality: 80, // Compress slightly to save space
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
    }
  }

  // 2. FUNCTION TO UPLOAD IMAGE TO FIREBASE STORAGE
  Future<String> _uploadImage(File image) async {
    try {
      // Create a unique filename based on time
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Reference to storage: /court_images/filename.jpg
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('court_images')
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Image Upload Failed: $e");
    }
  }

  void _saveCourt() async {
    if (_formKey.currentState!.validate()) {
      // Validation: Ensure an image exists (either new or existing)
      if (_pickedImageFile == null && _existingImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload an image for the court.")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final ownerId = AuthService().getCurrentUserId();
        if (ownerId == null) throw Exception("User not logged in");

        String finalImageUrl = '';

        // A. If user picked a NEW image, upload it
        if (_pickedImageFile != null) {
          finalImageUrl = await _uploadImage(_pickedImageFile!);
        } 
        // B. If not, keep the OLD URL
        else if (_existingImageUrl != null) {
          finalImageUrl = _existingImageUrl!;
        }

        // C. Prepare Data
        final newCourt = CourtModel(
          id: widget.courtToEdit?.id ?? '', 
          ownerId: ownerId,
          name: _nameController.text.trim(),
          type: _selectedType,
          pricePerHour: double.parse(_priceController.text.trim()),
          location: _locationController.text.trim(),
          description: _descController.text.trim(),
          imageUrl: finalImageUrl, // Use the real Firebase URL
          amenities: _selectedAmenities,
        );

        // D. Save to Firestore
        await DatabaseService().saveCourt(newCourt, isEditing: widget.courtToEdit != null);
        
        if (!mounted) return;
        Navigator.pop(context);
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
              
              // 🖼️ IMAGE PICKER AREA
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _pickedImageFile != null
                        ? DecorationImage(
                            image: FileImage(_pickedImageFile!), 
                            fit: BoxFit.cover,
                          )
                        : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(_existingImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (_pickedImageFile == null && _existingImageUrl == null)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Tap to upload court image", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Name
              CustomInput(
                label: "Court Name",
                icon: Icons.stadium,
                controller: _nameController,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),

              // 2. Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Sport Type",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category, color: Colors.blueAccent),
                ),
                items: ['Badminton', 'Futsal']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // 3. Price
              CustomInput(
                label: "Price per Hour (RM)",
                icon: Icons.attach_money,
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),

              // 4. Location
              CustomInput(
                label: "Location / Floor",
                icon: Icons.location_on,
                controller: _locationController,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),

              // 5. Description
              CustomInput(
                label: "Description & Rules",
                icon: Icons.description,
                controller: _descController,
              ),

              // 6. Amenities
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
              const SizedBox(height: 30),

              // SAVE BUTTON
              CustomButton(
                text: "SAVE COURT",
                isLoading: _isLoading,
                backgroundColor: Colors.blueGrey,
                onPressed: _saveCourt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}