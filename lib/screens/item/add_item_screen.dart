import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../config/colors.dart';
import '../../widgets/bottom_nav.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isLoading = false;
  String _selectedStatus = 'Found';
  XFile? _selectedImage;
  final List<String> _statusOptions = ['Found', 'Lost'];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    debugPrint('[AddItem] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/search');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/notifications');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
    // index 2 is add_item - we're already here
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Reduced from 1920 for faster processing
        maxHeight: 800, // Reduced from 1080 for faster processing
        imageQuality: 70, // Compress to 70% quality
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<String> _encodeImageToBase64(XFile file) async {
    debugPrint('🔄 Starting image compression and encoding...');
    try {
      final bytes = await file.readAsBytes();
      final originalSize = bytes.length;
      debugPrint(
        '📸 Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
      );

      // ✅ Validasi ukuran image
      if (originalSize > 5000000) {
        // 5MB limit
        throw '❌ Image too large (${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB). Max: 5 MB';
      }

      final encoded = base64Encode(bytes);
      final encodedSize = encoded.length;
      debugPrint(
        '✓ Image compressed and encoded. Base64 size: ${(encodedSize / 1024).toStringAsFixed(2)} KB',
      );

      // ✅ Prefix dengan data URL format untuk compatibility
      final dataUrl = 'data:image/jpeg;base64,$encoded';
      return dataUrl;
    } catch (e) {
      debugPrint('❌ Image encoding error: $e');
      rethrow; // Rethrow untuk ditangani di _submitForm
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    debugPrint('🔄 Starting form submission...');
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw '❌ User not authenticated';
      debugPrint('👤 Current user: ${user.uid}');

      // Encode image to base64 if selected
      String imageData = '';
      if (_selectedImage != null) {
        try {
          debugPrint('📸 Encoding image...');
          imageData = await _encodeImageToBase64(_selectedImage!);
          debugPrint(
            '✓ Image encoded: ${(imageData.length / 1024).toStringAsFixed(2)} KB',
          );
        } catch (encodeError) {
          debugPrint('❌ Image encoding failed: $encodeError');
          throw '❌ Image encoding error: $encodeError';
        }
      }

      final itemData = {
        'name': _nameController.text.trim(),
        'type': _typeController.text.trim(),
        'location': _locationController.text.trim(),
        'date': DateTime.now().toString().substring(0, 10),
        'description': _descController.text.trim(),
        'status': _selectedStatus,
        'image': imageData,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      debugPrint(
        '📝 Item data prepared: name=${itemData['name']}, status=${itemData['status']}',
      );

      final docRef = await FirebaseFirestore.instance
          .collection('items')
          .add(itemData);
      debugPrint('✓ Item submitted successfully! ID: ${docRef.id}');

      // Create notification for all users
      debugPrint('📢 Creating notification for all users...');
      try {
        // ✅ Standardized notification structure
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'new_item',
          'title': '${itemData['status']} Item: ${itemData['name']}',
          'description':
              '${user.email} posted a new ${itemData['status'].toString().toLowerCase()} item at ${itemData['location']}',
          'itemId': docRef.id,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        debugPrint('✓ Notification created!');
      } catch (notifError) {
        debugPrint('❌ Notification creation error: $notifError');
        // Don't fail the entire submission if notification fails
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item reported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Item Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? 'Found');
                    },
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Item Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter item name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Item name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Item Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Wallet, Keys, Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Item type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Location Found/Last Seen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Building A, Room 101',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe the item, color, brand, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Photo (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedImage != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _selectedImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: _selectedImage!.readAsBytes().then(
                                    (bytes) => Uint8List.fromList(bytes),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    }
                                    return Container(
                                      color: AppColors.surface,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to select photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'From gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Report Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 2, onTap: _onBottomNavTap),
    );
  }
}
