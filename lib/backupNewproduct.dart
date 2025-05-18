import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'header&nav.dart';
import 'providers/theme_provider.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

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

  // final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();
      final productName = _nameController.text.trim();

      //Check if the product already exists
      final allProducts = await db.getAllProducts();
      final duplicate = allProducts.any((product) =>
          product['name'].toString().toLowerCase() ==
          productName.toLowerCase());

      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Product already exists. Please add from "Add New Item".'),
            backgroundColor: darkShade1,
          ),
        );
        return;
      }

      final product = {
        'product_id': await _generateUniqueProductId(),
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
      };

      await DatabaseHelper().insertProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      setState(() {
        // _productIdController.clear();
        _nameController.clear();
        _categoryController.clear();
        _priceController.clear();
        _quantityController.clear();
        _brandController.clear();
        _lowStockController.clear();
        _descriptionController.clear();
        selectedUnit = 'KG';
      });
    }
  }

  Future<String> _generateUniqueProductId() async {
    final db = DatabaseHelper();
    String newId;
    bool exists = true;

    do {
      newId =
          (10000 + (DateTime.now().microsecondsSinceEpoch % 90000)).toString();
      final existingProduct = await db.getProductById(newId);
      exists = existingProduct != null;
    } while (exists);

    return newId;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(240, 0, 0, 0)
          : const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  opacity: 0.1,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : vibrantBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      isDark ? Colors.black45 : Colors.black12,
                                  blurRadius: 10)
                            ],
                            border: Border.all(
                                color: isDark ? Colors.white : brightBlue,
                                width: 2),
                          ),
                          child: Column(
                            children: [
                              // _buildTextField('Add Product ID',
                              //     controller: _productIdController,
                              //     isRequired: true,
                              //     isDark: isDark),
                              _buildTextField('Enter Category',
                                  controller: _categoryController,
                                  isRequired: true,
                                  isDark: isDark),
                              _buildTextField('Product Name',
                                  controller: _nameController,
                                  isRequired: true,
                                  isDark: isDark),
                              _buildTextField('Purchase Price/unit',
                                  controller: _priceController,
                                  isRequired: true,
                                  isNumber: true,
                                  isDark: isDark),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField('Quantity',
                                        controller: _quantityController,
                                        isRequired: true,
                                        isNumber: true,
                                        isDark: isDark),
                                  ),
                                  const SizedBox(width: 10),
                                  DropdownButton<String>(
                                    value: selectedUnit,
                                    dropdownColor:
                                        isDark ? darkShade1 : Colors.white,
                                    underline: Container(
                                      height: 2,
                                      color: isDark ? darkShade1 : deepIndigo,
                                    ),
                                    iconEnabledColor:
                                        isDark ? darkShade1 : deepIndigo,
                                    items: unitOptions.map((String unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit,
                                        child: Text(unit,
                                            style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black)),
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
                                  controller: _brandController, isDark: isDark),
                              _buildTextField('Set Low Stock Alert',
                                  controller: _lowStockController,
                                  isNumber: true,
                                  isDark: isDark),
                              _buildTextField('Description',
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  isDark: isDark),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark ? darkShade1 : brightBlue,
                                  side: BorderSide(
                                      color: isDark ? darkShade3 : deepIndigo,
                                      width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _addProduct,
                                child: const Text(
                                  'Add Product',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(context, null),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      bool isRequired = false,
      bool isNumber = false,
      int maxLines = 1,
      required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? darkShade1 : Colors.white,
          hintText: label,
          hintStyle: TextStyle(color: isDark ? Colors.white : deepIndigo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color:
                    isDark ? darkShade3 : const Color.fromARGB(255, 13, 0, 255),
                width: 2),
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
