// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'header&nav.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class NewProductPage extends StatefulWidget {
  const NewProductPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewProductPageState createState() => _NewProductPageState();
}

class _NewProductPageState extends State<NewProductPage> {
  final _formKey = GlobalKey<FormState>();
  String selectedUnit = 'KG';
  final Map<String, Map<String, String>> unitOptions = {
    'KG': {'en': 'KG', 'bn': 'কেজি'},
    'Pcs': {'en': 'Pcs', 'bn': 'টি'},
    'Litre': {'en': 'Litre', 'bn': 'লিটার'},
    'Dozen': {'en': 'Dozen', 'bn': 'ডজন'},
    'Bags': {'en': 'Bags', 'bn': 'ব্যাগ'},
    'Set': {'en': 'Set', 'bn': 'সেট'},
    'Gauge': {'en': 'Gauge', 'bn': 'গজ'},
    'Packet': {'en': 'Packet', 'bn': 'প্যাকেট'},
    'Carton': {'en': 'Carton', 'bn': 'কার্টন'},
    'SQ Metre': {'en': 'SQ Metre', 'bn': 'বর্গমিটার'},
    'Metre': {'en': 'Metre', 'bn': 'মিটার'},
    'SQ Feet': {'en': 'SQ Feet', 'bn': 'বর্গফুট'},
    'Feet': {'en': 'Feet', 'bn': 'ফুট'},
    'Inch': {'en': 'Inch', 'bn': 'ইঞ্চি'},
  };

  // final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addProduct() async {
    final themeProvider = context.read<ThemeProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();
      final productName = _nameController.text.trim();

      final allProducts = await db.getAllProducts();
      final duplicate = allProducts.any((product) =>
          product['name'].toString().toLowerCase() ==
          productName.toLowerCase());

      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBangla
                  ? 'পণ্য ইতোমধ্যে বিদ্যমান। দয়া করে "নতুন আইটেম যোগ করুন" থেকে যুক্ত করুন।'
                  : 'Product already exists. Please add from "Add New Item".',
            ),
            backgroundColor: isDark ? darkShade1 : deepIndigo,
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
        SnackBar(
          content: Text(
            isBangla
                ? 'পণ্য সফলভাবে যুক্ত হয়েছে!'
                : 'Product added successfully!',
          ),
          backgroundColor: isDark ? darkShade3 : brightBlue,
        ),
      );

      setState(() {
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

  void _showConfirmationDialog() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) {
          final isDark =
              Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
          final isBangla =
              Provider.of<LanguageProvider>(context, listen: false).isBangla;

          return AlertDialog(
            backgroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: isDark ? darkShade3 : deepIndigo,
                width: 1.5,
              ),
            ),
            title: Text(
              isBangla
                  ? 'পণ্যের বিবরণ নিশ্চিত করুন'
                  : 'Confirm Product Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : deepIndigo,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                      isBangla ? 'নাম' : 'Name', _nameController.text, isDark),
                  _buildSummaryRow(isBangla ? 'বিভাগ' : 'Category',
                      _categoryController.text, isDark),
                  _buildSummaryRow(isBangla ? 'দর / ইউনিট' : 'Price/unit',
                      _priceController.text, isDark),
                  _buildSummaryRow(isBangla ? 'পরিমাণ' : 'Quantity',
                      _quantityController.text, isDark),
                  _buildSummaryRow(
                      isBangla ? 'একক' : 'Unit',
                      isBangla
                          ? unitOptions[selectedUnit]!['bn']!
                          : selectedUnit,
                      isDark),
                  _buildSummaryRow(isBangla ? 'ব্র্যান্ড' : 'Brand',
                      _brandController.text, isDark),
                  _buildSummaryRow(
                      isBangla ? 'লো স্টক সতর্কতা' : 'Low Stock Alert',
                      _lowStockController.text,
                      isDark),
                  _buildSummaryRow(isBangla ? 'বিবরণ' : 'Description',
                      _descriptionController.text, isDark),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  isBangla ? 'বাতিল' : 'Cancel',
                  style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.black87),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? darkShade3 : brightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _addProduct();
                },
                child: Text(isBangla ? 'নিশ্চিত করুন' : 'Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label: ${value.isNotEmpty ? value : '—'}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.5,
          color: isDark ? Colors.white : deepIndigo,
        ),
      ),
    );
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

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
                              _buildTextField(
                                isBangla ? 'বিভাগ লিখুন' : 'Enter Category',
                                controller: _categoryController,
                                isRequired: true,
                                isDark: isDark,
                              ),
                              _buildTextField(
                                isBangla ? 'পণ্যের নাম' : 'Product Name',
                                controller: _nameController,
                                isRequired: true,
                                isDark: isDark,
                              ),
                              _buildTextField(
                                isBangla
                                    ? 'ক্রয় মূল্য / ইউনিট'
                                    : 'Purchase Price/unit',
                                controller: _priceController,
                                isRequired: true,
                                isNumber: true,
                                isDark: isDark,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      isBangla ? 'পরিমাণ' : 'Quantity',
                                      controller: _quantityController,
                                      isRequired: true,
                                      isNumber: true,
                                      isDark: isDark,
                                    ),
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
                                    items: unitOptions.entries.map((entry) {
                                      final unitKey = entry.key;
                                      final unitLabel = isBangla
                                          ? entry.value['bn']!
                                          : entry.value['en']!;
                                      return DropdownMenuItem<String>(
                                        value: unitKey,
                                        child: Text(unitLabel),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedUnit = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              _buildTextField(
                                isBangla ? 'ব্র্যান্ড নাম' : 'Brand Name',
                                controller: _brandController,
                                isDark: isDark,
                              ),
                              _buildTextField(
                                isBangla
                                    ? 'লো স্টক সতর্কতা সেট করুন'
                                    : 'Set Low Stock Alert',
                                controller: _lowStockController,
                                isNumber: true,
                                isDark: isDark,
                              ),
                              _buildTextField(
                                isBangla ? 'বিবরণ' : 'Description',
                                controller: _descriptionController,
                                maxLines: 3,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark ? darkShade1 : brightBlue,
                                  side: BorderSide(
                                    color: isDark ? darkShade3 : deepIndigo,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _showConfirmationDialog,
                                child: Text(
                                  isBangla ? 'পণ্য যোগ করুন' : 'Add Product',
                                  style: const TextStyle(
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
      bottomNavigationBar: bottomNav(context, null),
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
                final isBangla = context.read<LanguageProvider>().isBangla;

                if (value == null || value.trim().isEmpty) {
                  return isBangla
                      ? 'এই ঘরটি পূরণ করা আবশ্যক'
                      : 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
