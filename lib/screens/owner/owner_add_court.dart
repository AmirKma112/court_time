import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/court_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class OwnerAddCourt extends StatefulWidget {
  final CourtModel? courtToEdit;

  const OwnerAddCourt({super.key, this.courtToEdit});

  @override
  State<OwnerAddCourt> createState() => _OwnerAddCourtState();
}

class _OwnerAddCourtState extends State<OwnerAddCourt> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  
  File? _pickedImageFile;        
  String? _existingImageUrl;     

  String _selectedType = 'Badminton';
  final List<String> _availableAmenities = ['Air Cond', 'WiFi', 'Parking', 'Showers', 'Equipment Rent', 'Locker'];
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
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

  // ---------------------------------------------------------------------------
  // 1. FIXED: Dispose Controllers (Prevents Memory Leaks)
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, 
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
    }
  }

  // NOTE: In a larger app, move this method to a separate StorageService!
  Future<String> _uploadImage(File image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('court_images')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Image Upload Failed: $e");
    }
  }

  void _saveCourt() async {
    // 2. FIXED: Unfocus keyboard before saving
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
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

        if (_pickedImageFile != null) {
          finalImageUrl = await _uploadImage(_pickedImageFile!);
        } else if (_existingImageUrl != null) {
          finalImageUrl = _existingImageUrl!;
        }

        final newCourt = CourtModel(
          id: widget.courtToEdit?.id ?? '', 
          ownerId: ownerId,
          name: _nameController.text.trim(),
          type: _selectedType,
          // Safety: validation ensures this is a double now
          pricePerHour: double.parse(_priceController.text.trim()), 
          location: _locationController.text.trim(),
          description: _descController.text.trim(),
          imageUrl: finalImageUrl, 
          amenities: _selectedAmenities,
        );

        await DatabaseService().saveCourt(newCourt, isEditing: widget.courtToEdit != null);
        
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Court Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Court" : "Add New Court"),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      // 3. FIXED: Tap anywhere to close keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // 1. IMAGE UPLOAD SECTION
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      image: _pickedImageFile != null
                          ? DecorationImage(image: FileImage(_pickedImageFile!), fit: BoxFit.cover)
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_pickedImageFile == null && _existingImageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.orange),
                              ),
                              const SizedBox(height: 12),
                              Text("Tap to upload venue photo", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(12),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.edit, color: Colors.orange),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
    
                // 2. BASIC DETAILS CARD
                _buildSectionTitle("Basic Info"),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      CustomInput(
                        label: "Court Name",
                        icon: Icons.stadium_rounded,
                        controller: _nameController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: "Sport Type",
                          prefixIcon: const Icon(Icons.sports, color: Colors.blueAccent),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                        items: ['Badminton', 'Futsal']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                      const SizedBox(height: 16),
    
                      CustomInput(
                        label: "Price per Hour (RM)",
                        icon: Icons.attach_money_rounded,
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        // 4. FIXED: Better validation to prevent app crash on invalid number
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid price";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
    
                // 3. LOCATION & DESCRIPTION
                _buildSectionTitle("Details"),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      CustomInput(
                        label: "Location",
                        icon: Icons.location_on_rounded,
                        controller: _locationController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: "Description & Rules",
                        icon: Icons.description_rounded,
                        controller: _descController,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
    
                // 4. AMENITIES
                _buildSectionTitle("Amenities"),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        selectedColor: Colors.orange.withOpacity(0.2),
                        checkmarkColor: Colors.deepOrange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.deepOrange : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? Colors.orange : Colors.transparent),
                        ),
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
                ),
                const SizedBox(height: 30),
    
                CustomButton(
                  text: "SAVE COURT",
                  isLoading: _isLoading,
                  backgroundColor: Colors.deepOrange,
                  onPressed: _saveCourt,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}