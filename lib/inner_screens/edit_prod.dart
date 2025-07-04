import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/utils.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../consts/constants.dart'; // Add this line
import '../responsive.dart';
import '../controllers/MenuController.dart' as grocery;
import '../screens/loading_manager.dart';
import '../inner_screens/categories_screen.dart';
import '../widgets/reviews_management_widget.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/EditProductScreen';
  final String id;
  final String title;
  final String price;
  final String categoryName;
  final String imageUrl;
  final String description;
  final String nutrients;
  final int calories;

  const EditProductScreen({
    Key? key,
    required this.id,
    required this.title,
    required this.price,
    required this.categoryName,
    required this.imageUrl,
    required this.description,
    required this.nutrients,
    required this.calories,
  }) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  File? _pickedImage;
  Uint8List _webImage = Uint8List(8);
  bool _isLoading = false;
  bool _isInitialized = false;
  late TextEditingController _descriptionController;
  late TextEditingController _nutrientsController;
  late TextEditingController _caloriesController;
  bool _isOnSale = false;
  late TextEditingController _salePriceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _priceController = TextEditingController(text: widget.price);
    _webImage = base64Decode(widget.imageUrl);
    _descriptionController = TextEditingController(text: widget.description);
    _nutrientsController = TextEditingController(text: widget.nutrients);
    _caloriesController = TextEditingController(text: widget.calories.toString());
    _salePriceController = TextEditingController();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.id)
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final initialCategoryId = productData['categoryId'] as String?;
        final initialCategoryName = productData['categoryName'] as String?;

        setState(() {
          _isOnSale = productData['isOnSale'] ?? false;
          if (productData.containsKey('salePrice')) {
            _salePriceController.text = productData['salePrice'].toString();
          }
          _selectedCategoryId = initialCategoryId;
          _selectedCategoryName = initialCategoryName ?? widget.categoryName;
        });
      } else {
        setState(() {
          _selectedCategoryName = widget.categoryName;
        });
      }
    } catch (e) {
      print("Error loading initial product data: $e");
      setState(() {
        _selectedCategoryName = widget.categoryName;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _nutrientsController.dispose();
    _caloriesController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    // 1. Validate the form first
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    // 2. Check all conditions *before* setting isLoading
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form.')),
      );
      return; // Exit if form is invalid
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return; // Exit if category is not selected
    }

    // 3. Check sale price specifically if 'On Sale' is true
    if (_isOnSale && _salePriceController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Sale Price when "On Sale" is active.')),
      );
      return; // Exit if sale price is missing when required
    }

    // 4. If all checks pass, proceed with the update
    setState(() => _isLoading = true);
    
    try {
      String imageBase64;
      
      // Handle image update or keep existing one
      if (_webImage.lengthInBytes > 8) { // Check if a new image was picked
        imageBase64 = base64Encode(_webImage);
      } else {
        imageBase64 = widget.imageUrl; // Use existing image URL (already base64)
      }

      // Use double.tryParse for safety
      final price = double.tryParse(_priceController.text);
      final salePrice = _isOnSale ? double.tryParse(_salePriceController.text) : 0.0;
      final calories = int.tryParse(_caloriesController.text);

      if (price == null || (_isOnSale && salePrice == null) || calories == null) {
         throw Exception("Invalid number format for price, sale price, or calories.");
      }

      await FirebaseFirestore.instance.collection('products').doc(widget.id).update({
        'title': _titleController.text,
        'price': price,
        'categoryId': _selectedCategoryId, // Ensure this is set correctly
        'categoryName': _selectedCategoryName ?? widget.categoryName,
        'imageUrl': imageBase64,
        'isOnSale': _isOnSale,
        'salePrice': salePrice,
        'description': _descriptionController.text,
        'nutrients': _nutrientsController.text,
        'calories': calories,
        'updatedAt': Timestamp.now(),
      });

      // Success feedback and navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.pop(context);
        }
      });
    } catch (error) {
      // Error feedback
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) { // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating product: $error')),
          );
         }
      });
    } finally {
      // Ensure loading state is reset even if widget is disposed during async operation
      if (mounted) {
       setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _pickedImage = File(image.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;

    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getEditProductscaffoldKey,
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
                          context.read<grocery.GroceryMenuController>().controlEditProductsMenu();
                        },
                        title: 'Edit Product',
                      ),
                      const SizedBox(height: defaultPadding),
                      Container(
                        padding: const EdgeInsets.all(defaultPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(labelText: 'Product Title', filled: true),
                                validator: (value) => value!.isEmpty ? 'Title is required' : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Price', filled: true),
                                validator: (value) => value!.isEmpty ? 'Price is required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildCategoryDropdown(),
                              const SizedBox(height: 20),
                              _buildImageUploadSection(color),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('On Sale'),
                                      subtitle: const Text('Toggle this to mark product on sale'),
                                      value: _isOnSale,
                                      onChanged: (value) {
                                        setState(() {
                                          _isOnSale = value;
                                        });
                                      },
                                      activeColor: Theme.of(context).primaryColor,
                                    ),
                                    if (_isOnSale)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: TextFormField(
                                          controller: _salePriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Sale Price',
                                            filled: true,
                                            suffixIcon: Icon(Icons.price_change, color: Theme.of(context).primaryColor),
                                          ),
                                          validator: _isOnSale
                                              ? (value) => (value == null || value.isEmpty) 
                                                  ? 'Sale price is required when on sale' 
                                                  : null
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(labelText: 'Description', filled: true),
                                maxLines: 3,
                                validator: (value) => value!.isEmpty ? 'Description is required' : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nutrientsController,
                                decoration: InputDecoration(labelText: 'Nutrients', filled: true),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _caloriesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Calories', filled: true),
                              ),
                              const SizedBox(height: 30),
                              ReviewsManagementWidget(
                                productId: widget.id,
                                productTitle: widget.title,
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: _isLoading ? null : _updateProduct,
                                icon: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                    : const Icon(Icons.update),
                                label: Text(_isLoading ? 'Updating...' : 'Update Product'),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildProductForm(Size size, Color color) {
    return Container(
      width: size.width > 650 ? 650 : size.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Product Title', filled: true),
            validator: (value) => value!.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Price', filled: true),
            validator: (value) => value!.isEmpty ? 'Price is required' : null,
          ),
          const SizedBox(height: 20),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildImageUploadSection(color),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description', filled: true),
            maxLines: 3,
            validator: (value) => value!.isEmpty ? 'Description is required' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nutrientsController,
                  decoration: InputDecoration(labelText: 'Nutrients', filled: true),
                  validator: (value) => value!.isEmpty ? 'Nutrients are required' : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Calories', filled: true),
                  validator: (value) => value!.isEmpty ? 'Calories are required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('On Sale'),
                  subtitle: const Text('Toggle this to mark product on sale'),
                  value: _isOnSale,
                  onChanged: (value) {
                    setState(() {
                      _isOnSale = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                if (_isOnSale)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _salePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sale Price',
                        filled: true,
                        suffixIcon: Icon(Icons.price_change, color: Theme.of(context).primaryColor),
                      ),
                      validator: _isOnSale
                          ? (value) => (value == null || value.isEmpty) 
                              ? 'Sale price is required when on sale' 
                              : null
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _selectedCategoryId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Text('Error loading categories: ${snapshot.error}');
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return TextButton(
            onPressed: () => Navigator.pushNamed(context, CategoriesScreen.routeName),
            child: const Text('No categories found - Add Category'),
          );
        }

        final categories = snapshot.data!.docs;

        final validCategoryIds = categories.map((doc) => doc.id).toList();
        String? currentDropdownValue = _selectedCategoryId;
        if (!validCategoryIds.contains(currentDropdownValue)) {
          currentDropdownValue = null;
        }

        return DropdownButtonFormField<String>(
          value: currentDropdownValue,
          decoration: InputDecoration(
            labelText: 'Category',
            filled: true,
            hintText: _selectedCategoryName ?? 'Select Category',
          ),
          items: categories.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['name'] ?? 'Unnamed Category'),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final categoryDoc = categories.firstWhere((doc) => doc.id == value);
            final categoryData = categoryDoc.data() as Map<String, dynamic>;
            setState(() {
              _selectedCategoryId = value;
              _selectedCategoryName = categoryData['name'];
            });
          },
          validator: (value) => value == null ? 'Please select a category' : null,
        );
      },
    );
  }

  Widget _buildImageUploadSection(Color color) {
    return Column(
      children: [
        Text('Product Image', style: TextStyle(fontSize: 16, color: color)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _webImage.isNotEmpty || _pickedImage != null
                ? kIsWeb 
                    ? Image.memory(_webImage, fit: BoxFit.cover)
                    : Image.file(_pickedImage!, fit: BoxFit.cover)
                : (_webImage.isEmpty && widget.imageUrl.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: color),
                            const SizedBox(height: 8),
                            Text('Tap to add image', style: TextStyle(color: color)),
                          ],
                        ),
                      )
                    : Image.memory(base64Decode(widget.imageUrl), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildFormControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text(
                  'Update Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text(
              'Return to Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              minimumSize: const Size(220, 50),
            ),
          ),
        ],
      ),
    );
  }
}
