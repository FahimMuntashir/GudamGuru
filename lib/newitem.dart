// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'header&nav.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class NewItemPage extends StatefulWidget {
  const NewItemPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewItemPageState createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Map<String, dynamic>? selectedProduct;
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    allProducts = await DatabaseHelper().getAllProducts();
    setState(() {});
  }

  void _searchProduct(String query) {
    if (query.isEmpty) {
      setState(() => searchSuggestions = []);
    } else {
      setState(() {
        searchSuggestions = allProducts
            .where((p) =>
                p['product_id'].toLowerCase().contains(query.toLowerCase()) ||
                p['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  String _getLocalizedUnit(String unit, bool isBangla) {
    final unitMap = {
      'KG': 'কেজি',
      'Pcs': 'টি',
      'Litre': 'লিটার',
      'Dozen': 'ডজন',
      'Bags': 'ব্যাগ',
      'Set': 'সেট',
      'Gauge': 'গজ',
      'Packet': 'প্যাকেট',
      'Carton': 'কার্টন',
      'SQ Metre': 'বর্গমিটার',
      'Metre': 'মিটার',
      'SQ Feet': 'বর্গফুট',
      'Feet': 'ফুট',
      'Inch': 'ইঞ্চি',
    };

    return isBangla ? (unitMap[unit] ?? unit) : unit;
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product;
      _searchController.clear();
      searchSuggestions = [];
    });
  }

  Future<void> _addItem() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final isBangla = context.read<LanguageProvider>().isBangla;

    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBangla
              ? "কোনো পণ্য নির্বাচন করা হয়নি।"
              : "No product selected."),
          backgroundColor: isDark ? darkShade3 : deepIndigo,
        ),
      );
      return;
    }

    final String productId = selectedProduct!['product_id'];
    final double? purchasePrice = double.tryParse(_priceController.text);
    final int? quantity = int.tryParse(_quantityController.text);
    final String description = _descriptionController.text;

    if (purchasePrice == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBangla
              ? "দয়া করে সঠিক মূল্য এবং পরিমাণ লিখুন।"
              : "Please enter valid price and quantity."),
          backgroundColor: isDark ? darkShade3 : deepIndigo,
        ),
      );
      return;
    }

    await DatabaseHelper().insertStockEntry({
      'product_id': productId,
      'purchase_price': purchasePrice,
      'quantity': quantity,
      'description': description,
    });

    await DatabaseHelper().updateProductQuantity(productId, quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBangla
            ? "আইটেম সফলভাবে যুক্ত হয়েছে!"
            : "Item added successfully!"),
        backgroundColor: isDark ? darkShade3 : deepIndigo,
      ),
    );

    setState(() {
      _priceController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _searchController.clear();
      selectedProduct = null;
    });
  }

  void _showConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBangla ? "কোনো পণ্য নির্বাচন করা হয়নি।" : "No product selected.",
          ),
          backgroundColor: isDark ? darkShade3 : deepIndigo,
        ),
      );
      return;
    }

    final String productId = selectedProduct!['product_id'];
    final String productName = selectedProduct!['name'];
    final double? purchasePrice = double.tryParse(_priceController.text);
    final int? quantity = int.tryParse(_quantityController.text);
    final String description = _descriptionController.text;

    if (purchasePrice == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBangla
                ? "দয়া করে সঠিক মূল্য এবং পরিমাণ লিখুন।"
                : "Please enter valid price and quantity.",
          ),
          backgroundColor: isDark ? darkShade3 : deepIndigo,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isDark ? Colors.white70 : deepIndigo,
              width: 1.5,
            ),
          ),
          title: Text(
            isBangla ? 'আইটেম নিশ্চিত করুন' : 'Confirm Item Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : deepIndigo,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBoldRow(
                    isBangla ? 'পণ্য' : 'Product', productName, isDark),
                _buildBoldRow(
                    isBangla ? 'পণ্য আইডি' : 'Product ID', productId, isDark),
                _buildBoldRow(isBangla ? 'মূল্য' : 'Purchase Price',
                    purchasePrice.toString(), isDark),
                _buildBoldRow(isBangla ? 'পরিমাণ' : 'Quantity',
                    quantity.toString(), isDark),
                _buildBoldRow(
                  isBangla ? 'বর্ণনা' : 'Description',
                  description.isNotEmpty ? description : (isBangla ? '—' : '—'),
                  isDark,
                ),
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
                await _addItem();
              },
              child: Text(isBangla ? 'নিশ্চিত করুন' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoldRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.5,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
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
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
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
                              color: isDark ? Colors.black45 : Colors.black12,
                              blurRadius: 10,
                            )
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white : brightBlue,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            if (searchSuggestions.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchSuggestions.length,
                                itemBuilder: (context, index) {
                                  final product = searchSuggestions[index];
                                  return ListTile(
                                    title: Text(product['name']),
                                    subtitle:
                                        Text('ID: ${product['product_id']}'),
                                    onTap: () => _selectProduct(product),
                                  );
                                },
                              ),
                            const SizedBox(height: 10),
                            if (selectedProduct != null)
                              _buildProductDetails(selectedProduct!),
                            _buildTextField(
                              isBangla ? "ক্রয় মূল্য" : "New Purchase Price",
                              controller: _priceController,
                              isNumber: true,
                            ),
                            _buildTextField(
                              isBangla ? "পরিমাণ" : "Quantity",
                              controller: _quantityController,
                              isNumber: true,
                            ),
                            _buildTextField(
                              isBangla
                                  ? "বর্ণনা (ঐচ্ছিক)"
                                  : "Description (Optional)",
                              controller: _descriptionController,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _showConfirmationDialog,
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
                              child: Text(
                                isBangla ? "আইটেম যোগ করুন" : "Add Item",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
        ],
      ),
      bottomNavigationBar: bottomNav(context, null),
    );
  }

  Widget _buildSearchBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return TextField(
      controller: _searchController,
      onChanged: _searchProduct,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: isBangla
            ? 'পণ্যের আইডি বা নাম দিয়ে খুঁজুন'
            : 'Search by Product ID or Name',
        hintStyle: TextStyle(color: isDark ? Colors.white70 : deepIndigo),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? Colors.white : deepIndigo,
        ),
        filled: true,
        fillColor: isDark ? darkShade1 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? darkShade3 : const Color.fromARGB(255, 13, 0, 255),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> product) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? darkShade1.withOpacity(0.8)
                    : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? darkShade3 : deepIndigo,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla
                        ? 'নাম: ${product['name']}   (আইডি: ${product['product_id']})'
                        : 'Name: ${product['name']}   (ID: ${product['product_id']})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(isBangla
                      ? 'ব্র্যান্ড: ${product['brand_name'] ?? ''}'
                      : 'Brand: ${product['brand_name'] ?? ''}'),
                  Text(
                    isBangla
                        ? 'একক: ${_getLocalizedUnit(product['unit'] ?? '', true)}'
                        : 'Unit: ${_getLocalizedUnit(product['unit'] ?? '', false)}',
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon:
                    Icon(Icons.cancel, color: isDark ? darkShade3 : deepIndigo),
                tooltip: isBangla ? 'মুছুন' : 'Unselect',
                onPressed: () {
                  setState(() {
                    selectedProduct = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint,
      {TextEditingController? controller,
      int maxLines = 1,
      bool isNumber = false}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? darkShade1 : Colors.white,
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white : deepIndigo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color:
                    isDark ? darkShade3 : const Color.fromARGB(255, 13, 0, 255),
                width: 2),
          ),
        ),
      ),
    );
  }
}
