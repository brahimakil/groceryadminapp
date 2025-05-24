import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../consts/constants.dart'; // Add this line
import 'package:uuid/uuid.dart';
import '../services/utils.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../widgets/text_widget.dart';
import '../responsive.dart';
import '../controllers/MenuController.dart' as grocery;
import '../screens/loading_manager.dart';
import '../inner_screens/categories_screen.dart';

class UploadProductForm extends StatefulWidget {
  static const routeName = '/UploadProductForm';
  const UploadProductForm({Key? key}) : super(key: key);

  @override
  State<UploadProductForm> createState() => _UploadProductFormState();
}

class _UploadProductFormState extends State<UploadProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nutrientsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  File? _pickedImage;
  Uint8List _webImage = Uint8List(8);
  bool _isLoading = false;
  bool _isPiece = false;
  bool _isOnSale = false;

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

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid && _selectedCategoryId != null) {
      setState(() => _isLoading = true);
      
      try {
        final uuid = Uuid().v4();
        String imageBase64 = _webImage.isNotEmpty 
            ? base64Encode(_webImage) 
            : base64Encode(await _pickedImage!.readAsBytes());

        await FirebaseFirestore.instance.collection('products').doc(uuid).set({
          'id': uuid,
          'title': _titleController.text,
          'price': double.parse(_priceController.text),
          'categoryId': _selectedCategoryId,
          'categoryName': _selectedCategoryName,
          'imageUrl': imageBase64,
          'isPiece': _isPiece,
          'isOnSale': _isOnSale,
          'salePrice': _isOnSale ? double.parse(_salePriceController.text) : 0.0,
          'description': _descriptionController.text,
          'nutrients': _nutrientsController.text,
          'calories': int.parse(_caloriesController.text),
          'createdAt': Timestamp.now(),
        });
        
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _nutrientsController.clear();
    _caloriesController.clear();
    _salePriceController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _pickedImage = null;
      _webImage = Uint8List(8);
      _isOnSale = false;
    });
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
      key: context.read<grocery.GroceryMenuController>().getAddProductscaffoldKey,
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
                          context.read<grocery.GroceryMenuController>().controlAddProductsMenu();
                        },
                        title: 'Add New Product',
                      ),
                      const SizedBox(height: defaultPadding),
                      Container(
                        padding: const EdgeInsets.all(defaultPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildForm(color, size),
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

  Widget _buildForm(Color color, Size size) {
    return Form(
      key: _formKey,
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
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildImageUploadSection(color),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('On Sale'),
                      trailing: Switch(
                        value: _isOnSale,
                        onChanged: (value) {
                          setState(() {
                            _isOnSale = value;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (_isOnSale)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ],
          ),
          const SizedBox(height: 20),
          _buildFormControls(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) return CircularProgressIndicator();

        final categories = snapshot.data!.docs;
        if (categories.isEmpty) {
          return TextButton(
            onPressed: () => Navigator.pushNamed(context, CategoriesScreen.routeName),
            child: Text('No categories found - Add Category'),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(labelText: 'Category', filled: true),
          items: categories.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['name'] ?? 'Unnamed Category'),
            );
          }).toList(),
          onChanged: (value) {
            final category = categories.firstWhere((doc) => doc.id == value);
            setState(() {
              _selectedCategoryId = value;
              _selectedCategoryName = (category.data() as Map<String, dynamic>)['name'];
            });
          },
          validator: (value) => value == null ? 'Category is required' : null,
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
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: color),
                        const SizedBox(height: 8),
                        Text('Tap to add image', style: TextStyle(color: color)),
                      ],
                    ),
                  ),
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
                onPressed: _clearForm,
                child: const Text(
                  'Clear Form',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text(
                  'Submit Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
