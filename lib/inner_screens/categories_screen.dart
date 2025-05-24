import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../consts/constants.dart'; // Add this line
import 'package:grocery_admin_panel/models/category_model.dart';
import 'package:grocery_admin_panel/services/global_method.dart';
import 'package:grocery_admin_panel/services/utils.dart';
import 'package:grocery_admin_panel/widgets/header.dart';
import 'package:grocery_admin_panel/widgets/side_menu.dart';
import 'package:grocery_admin_panel/widgets/text_widget.dart';
import 'package:grocery_admin_panel/responsive.dart';
import 'package:grocery_admin_panel/widgets/buttons.dart';
import 'package:grocery_admin_panel/controllers/MenuController.dart' as grocery;
import 'package:grocery_admin_panel/screens/loading_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
    if (!kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        var selected = File(image.path);
        setState(() {
          _pickedImage = selected;
        });
      }
    } else if (kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        var f = await image.readAsBytes();
        setState(() {
          _pickedImage = File("a");
          webImage = f;
        });
      }
    }
  }

  Future<void> _addCategory() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final categoryId = const Uuid().v4();
        String? imageUrl;
        
        // Convert image to Base64 if available
        if (_pickedImage != null || webImage.lengthInBytes > 10) {
          String base64Image;
          if (kIsWeb) {
            base64Image = base64Encode(webImage);
          } else {
            List<int> imageBytes = await _pickedImage!.readAsBytes();
            base64Image = base64Encode(imageBytes);
          }
          // Store as base64 string directly
          imageUrl = base64Image;
        }
        
        await FirebaseFirestore.instance.collection('categories').doc(categoryId).set({
          'id': categoryId,
          'name': _categoryNameController.text.trim(),
          'imageUrl': imageUrl,
          'createdAt': Timestamp.now(),
        });
        
        _categoryNameController.clear();
        setState(() {
          _pickedImage = null;
          webImage = Uint8List(8);
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (error) {
        String errorMessage = error.toString();
        // Check for permission errors
        if (errorMessage.contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your Firestore security rules.';
        }
        
        GlobalMethods.errorDialog(
          subtitle: 'Failed to add category: $errorMessage', 
          context: context
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('categories').doc(id).delete();
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      String errorMessage = error.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Make sure you have the right permissions to delete categories.';
      }
      
      GlobalMethods.errorDialog(
        subtitle: 'Failed to delete category: $errorMessage', 
        context: context
      );
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
        color: Colors.grey[300],
        child: Icon(Icons.category, color: Colors.grey[700], size: size / 2),
      );
    }
    
    try {
      // Try to decode the base64 string with adjusted fit and container size
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0), // Increased padding to zoom out more
          child: Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.contain, // Keep contain for better image display
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                height: size,
                width: size,
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.red, size: size / 2),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // If base64 decoding fails, try as network image
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                height: size,
                width: size,
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.red, size: size / 2),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;

    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getCategoriesScaffoldKey,
      drawer: const SideMenu(),
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
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    children: [
                      Header(
                        fct: () {
                          context.read<grocery.GroceryMenuController>().controlCategoriesMenu();
                        },
                        title: 'Categories',
                      ),
                      const SizedBox(height: defaultPadding),
                      Container(
                        width: size.width > 650 ? 650 : size.width,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: TextWidget(
                                  text: 'Add New Category',
                                  color: color,
                                  isTitle: true,
                                  textSize: 22,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text: 'Category Icon',
                                          color: color,
                                          isTitle: true,
                                        ),
                                        const SizedBox(height: 10),
                                        // Image picker
                                        GestureDetector(
                                          onTap: () {
                                            _pickImage();
                                          },
                                          child: Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).scaffoldBackgroundColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: color.withOpacity(0.3),
                                              ),
                                            ),
                                            child: _pickedImage == null
                                                ? DottedBorder(
                                                    dashPattern: const [6, 7],
                                                    borderType: BorderType.RRect,
                                                    radius: const Radius.circular(12),
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.image_outlined,
                                                            color: color,
                                                            size: 50,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          TextWidget(
                                                            text: 'Tap to select icon',
                                                            color: color,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : kIsWeb
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.memory(webImage, fit: BoxFit.cover),
                                                      )
                                                    : ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                                                      ),
                                          ),
                                        ),
                                        if (_pickedImage != null) 
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _pickedImage = null;
                                                webImage = Uint8List(8);
                                              });
                                            },
                                            icon: const Icon(Icons.clear, color: Colors.red),
                                            label: const Text('Clear image', style: TextStyle(color: Colors.red)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text: 'Category Name',
                                          color: color,
                                          isTitle: true,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _categoryNameController,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a category name';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Theme.of(context).scaffoldBackgroundColor,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: color.withOpacity(0.3)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: color.withOpacity(0.3)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: color),
                                            ),
                                            hintText: 'Enter category name',
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ButtonsWidget(
                                            onPressed: () {
                                              _addCategory();
                                            },
                                            text: 'Add Category',
                                            icon: Icons.add,
                                            backgroundColor: Colors.blue,
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
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color: color,
                                  ),
                                  const SizedBox(width: 10),
                                  TextWidget(
                                    text: 'Available Categories',
                                    color: color,
                                    textSize: 20,
                                    isTitle: true,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                .collection('categories')
                                .orderBy('createdAt', descending: true)
                                .limit(20)
                                .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                                  );
                                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Center(child: Text('No categories found. Add your first category!')),
                                  );
                                }
                                
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide.none,
                                      ),
                                    ),
                                    columns: [
                                      DataColumn(label: Text('Icon', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                                      DataColumn(label: Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                                      DataColumn(label: Text('Created On', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                                    ],
                                    rows: List.generate(
                                      snapshot.data!.docs.length,
                                      (index) {
                                        final categoryData = snapshot.data!.docs[index];
                                        final category = CategoryModel.fromFirestore(categoryData);
                                        
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Container(
                                                width: 60,
                                                height: 60,
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: _buildCategoryImage(category.imageUrl, 52),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(category.name, style: TextStyle(color: color)),
                                            ),
                                            DataCell(
                                              Text(
                                                '${category.createdAt.toDate().day}/${category.createdAt.toDate().month}/${category.createdAt.toDate().year}',
                                                style: TextStyle(color: color),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      GlobalMethods.warningDialog(
                                                        title: 'Delete ${category.name}?',
                                                        subtitle: 'Do you want to delete this category?',
                                                        fct: () {
                                                          Navigator.pop(context);
                                                          _deleteCategory(category.id);
                                                        },
                                                        context: context,
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 