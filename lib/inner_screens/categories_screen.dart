import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../consts/constants.dart';
import 'package:grocery_admin_panel/services/global_method.dart';
import 'package:grocery_admin_panel/services/utils.dart';
import 'package:grocery_admin_panel/widgets/header.dart';
import 'package:grocery_admin_panel/widgets/side_menu.dart';
import 'package:grocery_admin_panel/responsive.dart';
import 'package:grocery_admin_panel/controllers/MenuController.dart' as grocery;
import 'package:grocery_admin_panel/screens/loading_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  static const String routeName = '/CategoriesScreen';
  
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryNameController = TextEditingController();
  bool _isLoading = false;
  File? _pickedImage;
  Uint8List webImage = Uint8List(8);

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          var f = await image.readAsBytes();
          setState(() {
            webImage = f;
            _pickedImage = File("web_image"); // Placeholder for web
          });
        } else {
          var selected = File(image.path);
          setState(() {
            _pickedImage = selected;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryId = const Uuid().v4();
      String? imageUrl;
      
      // Convert image to Base64 if available
      if (_pickedImage != null && (kIsWeb ? webImage.isNotEmpty : true)) {
        String base64Image;
        if (kIsWeb) {
          base64Image = base64Encode(webImage);
        } else {
          List<int> imageBytes = await _pickedImage!.readAsBytes();
          base64Image = base64Encode(imageBytes);
        }
        imageUrl = base64Image;
      }
      
      await FirebaseFirestore.instance.collection('categories').doc(categoryId).set({
        'id': categoryId,
        'name': _categoryNameController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });
      
      // Clear form
      _categoryNameController.clear();
      setState(() {
        _pickedImage = null;
        webImage = Uint8List(8);
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('Error adding category: $error');
      String errorMessage = error.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your Firestore security rules.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add category: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(String id, String name) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('categories').doc(id).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting category: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryImage(String? imageUrl, double size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppTheme.neutral200,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(
          Icons.category,
          color: AppTheme.neutral500,
          size: size * 0.4,
        ),
      );
    }
    
    try {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                height: size,
                width: size,
                color: AppTheme.neutral200,
                child: Icon(
                  Icons.error,
                  color: Colors.red,
                  size: size * 0.4,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppTheme.neutral200,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(
          Icons.error,
          color: Colors.red,
          size: size * 0.4,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getCategoriesScaffoldKey,
      drawer: !Responsive.isDesktop(context) ? const SideMenu() : null,
      body: LoadingManager(
        isLoading: _isLoading,
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Responsive.isDesktop(context))
                const Expanded(
                  child: SideMenu(),
                ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Header(
                      fct: () {
                        context.read<grocery.GroceryMenuController>().controlCategoriesMenu();
                      },
                      title: 'Categories',
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.secondaryColor,
                                    AppTheme.secondaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Manage Categories',
                                          style: AppTheme.headlineLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacingSm),
                                        Text(
                                          'Organize your products with categories',
                                          style: AppTheme.bodyLarge.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingXl),
                            
                            // Add Category Section
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                border: Border.all(color: Theme.of(context).dividerColor),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add New Category',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingLg),
                                    
                                    // Image Picker Section
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Image Preview
                                        Container(
                                          width: 120,
                                          height: 120,
                                          child: _pickedImage != null && (kIsWeb ? webImage.isNotEmpty : true)
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                    child: kIsWeb
                                                        ? Image.memory(
                                                            webImage,
                                                            fit: BoxFit.cover,
                                                            width: 120,
                                                            height: 120,
                                                          )
                                                        : Image.file(
                                                            _pickedImage!,
                                                            fit: BoxFit.cover,
                                                            width: 120,
                                                            height: 120,
                                                          ),
                                                  ),
                                                )
                                              : DottedBorder(
                                                  borderType: BorderType.RRect,
                                                  radius: Radius.circular(AppTheme.radiusMd),
                                                  dashPattern: const [6, 3],
                                                  color: AppTheme.neutral400,
                                                  strokeWidth: 2,
                                                  child: Container(
                                                    width: 120,
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.neutral100,
                                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.cloud_upload_outlined,
                                                          size: 32,
                                                          color: AppTheme.neutral500,
                                                        ),
                                                        const SizedBox(height: AppTheme.spacingSm),
                                                        Text(
                                                          'Upload Image',
                                                          style: AppTheme.bodySmall.copyWith(
                                                            color: AppTheme.neutral500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        
                                        const SizedBox(width: AppTheme.spacingLg),
                                        
                                        // Form Fields
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Category Name Input
                                              TextFormField(
                                                controller: _categoryNameController,
                                                decoration: InputDecoration(
                                                  labelText: 'Category Name *',
                                                  hintText: 'Enter category name',
                                                  prefixIcon: const Icon(Icons.category),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                  ),
                                                  filled: true,
                                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.trim().isEmpty) {
                                                    return 'Please enter a category name';
                                                  }
                                                  if (value.trim().length < 2) {
                                                    return 'Category name must be at least 2 characters';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              
                                              const SizedBox(height: AppTheme.spacingMd),
                                              
                                              // Image Upload Button
                                              Row(
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: _pickImage,
                                                    icon: const Icon(Icons.image),
                                                    label: Text(_pickedImage != null ? 'Change Image' : 'Select Image'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.secondaryColor,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: AppTheme.spacingLg,
                                                        vertical: AppTheme.spacingMd,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_pickedImage != null) ...[
                                                    const SizedBox(width: AppTheme.spacingMd),
                                                    TextButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          _pickedImage = null;
                                                          webImage = Uint8List(8);
                                                        });
                                                      },
                                                      icon: const Icon(Icons.clear),
                                                      label: const Text('Remove'),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              
                                              const SizedBox(height: AppTheme.spacingLg),
                                              
                                              // Add Button
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: _isLoading ? null : _addCategory,
                                                  icon: _isLoading 
                                                      ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        )
                                                      : const Icon(Icons.add),
                                                  label: Text(_isLoading ? 'Adding...' : 'Add Category'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryColor,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                      vertical: AppTheme.spacingMd,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingXl),
                            
                            // Categories List
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                border: Border.all(color: Theme.of(context).dividerColor),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Available Categories',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingMd,
                                          vertical: AppTheme.spacingSm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        ),
                                        child: Text(
                                          'Live Data',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingLg),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('categories')
                                        .orderBy('createdAt', descending: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        );
                                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppTheme.spacingXl),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.category_outlined,
                                                  size: 64,
                                                  color: AppTheme.neutral400,
                                                ),
                                                const SizedBox(height: AppTheme.spacingMd),
                                                Text(
                                                  'No categories found',
                                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    color: AppTheme.neutral500,
                                                  ),
                                                ),
                                                const SizedBox(height: AppTheme.spacingSm),
                                                Text(
                                                  'Add your first category to get started!',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppTheme.neutral400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return _buildCategoriesGrid(snapshot.data!.docs);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(List<QueryDocumentSnapshot> docs) {
    return Responsive(
      mobile: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 4,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        itemCount: docs.length,
        itemBuilder: (context, index) => _buildCategoryCard(docs[index]),
      ),
      tablet: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        itemCount: docs.length,
        itemBuilder: (context, index) => _buildCategoryCard(docs[index]),
      ),
      desktop: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        itemCount: docs.length,
        itemBuilder: (context, index) => _buildCategoryCard(docs[index]),
      ),
    );
  }

  Widget _buildCategoryCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final imageUrl = data['imageUrl'];
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _buildCategoryImage(imageUrl, 60),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Created: ${createdAt.toDate().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteCategory(doc.id, name),
            icon: const Icon(Icons.delete),
            color: Colors.red,
            tooltip: 'Delete Category',
          ),
        ],
      ),
    );
  }
} 