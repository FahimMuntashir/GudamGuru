import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'reportanalytics.dart';
import 'profile.dart';
import 'UserSession.dart';

class NewProductPage extends StatefulWidget {
  const NewProductPage({super.key});

  @override
  _NewProductPageState createState() => _NewProductPageState();
}

class _NewProductPageState extends State<NewProductPage> {
  final _formKey = GlobalKey<FormState>();

  String selectedUnit = 'KG';
  final List<String> unitOptions = [
    'KG',
    'Pcs',
    'Litre',
    'Dozen',
    'Bags',
    'Set',
    'Gauge',
    'Packet',
    'Carton',
    'SQ Metre',
    'Metre',
    'SQ Feet',
    'Feet',
    'Inch'
  ];

  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, basename(pickedFile.path));
      final savedImage = await File(pickedFile.path).copy(imagePath);
      setState(() {
        _image = savedImage;
        _productIdController.text = 'P${DateTime.now().millisecondsSinceEpoch}';
        _nameController.text = 'Detected Product';
      });
    }
  }

  Future<void> _addProduct() async {
    print("Add Product button pressed");
    if (_formKey.currentState!.validate()) {
      print("Form is valid");

      final product = {
        'product_id': _productIdController.text.trim(),
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'purchase_price': double.tryParse(_priceController.text) ?? 0.0,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'unit': selectedUnit,
        'brand_name': _brandController.text.trim(),
        'low_stock_alert': _lowStockController.text.isNotEmpty
            ? int.tryParse(_lowStockController.text)
            : null,
        'description': _descriptionController.text.trim(),
        'image_path': _image?.path,
      };

      await DatabaseHelper().insertProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => const InventoryPage()),
      //   (Route<dynamic> route) => false,
      // );
    } else {
      print("Form is not valid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset('assets/images/logo.png', width: 150),
                              Text(
                                (UserSession().companyName ?? ''),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDE0FF).withOpacity(0.75),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: _buildQuickActionButton(
                                          'assets/images/cam.png',
                                          'Take a Picture'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                        'assets/images/barcode.png',
                                        'Scan Barcode'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildTextField('Add Product ID',
                                  controller: _productIdController,
                                  isRequired: true),
                              _buildTextField('Enter Category',
                                  controller: _categoryController,
                                  isRequired: true),
                              _buildTextField('Product Name',
                                  controller: _nameController,
                                  isRequired: true),
                              _buildTextField('Purchase Price/unit',
                                  controller: _priceController,
                                  isRequired: true,
                                  isNumber: true),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField('Quantity',
                                        controller: _quantityController,
                                        isRequired: true,
                                        isNumber: true),
                                  ),
                                  const SizedBox(width: 10),
                                  DropdownButton<String>(
                                    value: selectedUnit,
                                    items: unitOptions.map((String unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit,
                                        child: Text(unit),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedUnit = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              _buildTextField('Brand Name',
                                  controller: _brandController),
                              _buildTextField('Set Low Stock Alert',
                                  controller: _lowStockController,
                                  isNumber: true),
                              _buildTextField('Description',
                                  controller: _descriptionController,
                                  maxLines: 3),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff9b89ff),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _addProduct,
                          child: const Text('Add Product',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff000000),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          }
          if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const InventoryPage()));
          }
          if (index == 2) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReportAnalyticsPage()));
          }
          if (index == 3) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Report & Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String iconPath, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 40, height: 40),
          const SizedBox(height: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint,
      {TextEditingController? controller,
      int maxLines = 1,
      bool isRequired = false,
      bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: isRequired
            ? (value) => (value == null || value.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
