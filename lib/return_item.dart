// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'header&nav.dart';
import 'database_helper.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'return_history.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class ReturnItemPage extends StatefulWidget {
  const ReturnItemPage({super.key});

  @override
  State<ReturnItemPage> createState() => _ReturnItemPageState();
}

class _ReturnItemPageState extends State<ReturnItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _sellPriceController = TextEditingController();
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProduct;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  List<Map<String, dynamic>> _searchSuggestions = [];

  void _searchProduct(String query) {
    if (query.isEmpty) {
      setState(() => _searchSuggestions = []);
    } else {
      setState(() {
        _searchSuggestions = _products
            .where((p) =>
                p['product_id'].toLowerCase().contains(query.toLowerCase()) ||
                p['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _selectedProductId = product['product_id'];
      _searchSuggestions = [];
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await DatabaseHelper().getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
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

  Future<void> _processReturn() async {
    final isBangla =
        Provider.of<LanguageProvider>(context, listen: false).isBangla;

    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      try {
        final quantity = int.parse(_quantityController.text);
        final reason = _reasonController.text;
        final sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
        final productId = _selectedProduct!['product_id'];

        //sale
        final allSales = await DatabaseHelper().getAllSales();
        final productSales = allSales
            .where((sale) =>
                sale['product_id'] == productId &&
                sale['stock_entry_id'] != null)
            .toList();

        productSales.sort((a, b) => DateTime.parse(b['date_sold'])
            .compareTo(DateTime.parse(a['date_sold'])));

        int? stockEntryId = productSales.isNotEmpty
            ? productSales.first['stock_entry_id']
            : null;

        //Fallback to latest stock entry if no sale entry is linked
        if (stockEntryId == null) {
          final stockEntries =
              await DatabaseHelper().getStockEntriesForProduct(productId);
          if (stockEntries.isNotEmpty) {
            stockEntryId = stockEntries.last['id'];
          }
        }

        // return record
        await DatabaseHelper().insertReturn({
          'product_id': productId,
          'quantity': quantity,
          'reason': reason,
          'sell_price': sellPrice,
          'stock_entry_id': stockEntryId,
          'date_returned': DateTime.now().toIso8601String(),
        });

        //Add a new stock entry using existing helper
        await DatabaseHelper().increaseStockEntryQuantityFromReturn(
          productId: productId,
          quantity: quantity,
          stockEntryId: stockEntryId,
        );

        //Update total product quantity
        await DatabaseHelper().updateProductQuantity(productId, quantity);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBangla
                    ? 'ফেরত সফলভাবে সম্পন্ন হয়েছে'
                    : 'Item returned successfully',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error processing return: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBangla
                    ? 'ফেরত প্রক্রিয়াকরণে সমস্যা হয়েছে: $e'
                    : 'Error processing return: $e',
              ),
            ),
          );
        }
      }
    }
  }

  void _showReturnConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final productName = _selectedProduct!['name'];
      final productId = _selectedProduct!['product_id'];
      final quantity = _quantityController.text.trim();
      final sellPrice = _sellPriceController.text.trim();
      final reason = _reasonController.text.trim();

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
              isBangla ? 'ফেরতের বিবরণ নিশ্চিত করুন' : 'Confirm Return Details',
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
                  _buildBoldRow(isBangla ? 'ফেরতের পরিমাণ' : 'Return Quantity',
                      quantity, isDark),
                  _buildBoldRow(isBangla ? 'বিক্রয় মূল্য' : 'Sell Price',
                      sellPrice, isDark),
                  _buildBoldRow(
                    isBangla ? 'কারণ' : 'Reason',
                    reason.isNotEmpty ? reason : (isBangla ? '—' : '—'),
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
                    color: isDark ? Colors.grey[300] : Colors.black87,
                  ),
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
                  await _processReturn();
                },
                child: Text(isBangla ? 'নিশ্চিত করুন' : 'Confirm'),
              ),
            ],
          );
        },
      );
    } else {
      final isBangla =
          Provider.of<LanguageProvider>(context, listen: false).isBangla;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBangla
              ? "অনুগ্রহ করে সব ঘর পূরণ করুন এবং একটি পণ্য নির্বাচন করুন।"
              : "Please fill all fields and select a product."),
        ),
      );
    }
  }

  Widget _buildBoldRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.5,
          color: isDark ? Colors.white : deepIndigo,
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
            borderSide:
                BorderSide(color: isDark ? darkShade3 : brightBlue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(Map<String, dynamic> product) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? darkShade1.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark ? darkShade3 : deepIndigo, width: 1.5),
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
              icon: Icon(Icons.cancel, color: isDark ? darkShade3 : deepIndigo),
              tooltip: isBangla ? 'মুছুন' : 'Unselect',
              onPressed: () {
                setState(() {
                  _selectedProduct = null;
                  _selectedProductId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProductDropdown() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? darkShade1 : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: _selectedProductId != null
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: isDark ? Colors.white : deepIndigo),
                  onPressed: () {
                    setState(() {
                      _selectedProductId = null;
                      _selectedProduct = null;
                    });
                  },
                )
              : null,
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
            borderSide:
                BorderSide(color: isDark ? darkShade3 : brightBlue, width: 2),
          ),
        ),
        dropdownColor: isDark ? darkShade1 : Colors.white,
        value: _selectedProductId,
        hint: Center(
          child: Text(
            "Select Product",
            style: TextStyle(color: isDark ? Colors.white : deepIndigo),
          ),
        ),
        items: _products.map((product) {
          return DropdownMenuItem<String>(
            value: product['product_id'],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                product['name'],
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProductId = value;
            _selectedProduct =
                _products.firstWhere((p) => p['product_id'] == value);
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a product';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProductSearchBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Column(
      children: [
        TextField(
          onChanged: _searchProduct,
          decoration: InputDecoration(
            hintText: isBangla
                ? 'পণ্যের আইডি বা নাম দিয়ে খুঁজুন'
                : 'Search Product by ID or Name',
            hintStyle: TextStyle(color: isDark ? Colors.white : deepIndigo),
            prefixIcon:
                Icon(Icons.search, color: isDark ? Colors.white : deepIndigo),
            filled: true,
            fillColor: isDark ? darkShade1 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark ? darkShade2 : deepIndigo, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark ? darkShade2 : deepIndigo, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark
                      ? darkShade3
                      : const Color.fromARGB(255, 13, 0, 255),
                  width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_searchSuggestions.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: _searchSuggestions.length,
            itemBuilder: (context, index) {
              final product = _searchSuggestions[index];
              return ListTile(
                title: Text(product['name']),
                subtitle: Text(isBangla
                    ? 'আইডি: ${product['product_id']}'
                    : 'ID: ${product['product_id']}'),
                onTap: () => _selectProduct(product),
              );
            },
          ),
        const SizedBox(height: 10),
        if (_selectedProduct != null) _buildProductInfoCard(_selectedProduct!),
      ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(15),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : vibrantBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black45
                                        : Colors.black12,
                                    blurRadius: 10,
                                  )
                                ],
                                border: Border.all(
                                  color: isDark ? Colors.white : brightBlue,
                                  width: 2,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildProductSearchBar(),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      isBangla
                                          ? 'ফেরতের পরিমাণ'
                                          : 'Return Quantity',
                                      controller: _quantityController,
                                      isNumber: true,
                                    ),
                                    _buildTextField(
                                      isBangla
                                          ? 'বিক্রয় মূল্য (ফেরতের)'
                                          : 'Return Sell Price',
                                      controller: _sellPriceController,
                                      isNumber: true,
                                    ),
                                    _buildTextField(
                                      isBangla
                                          ? 'ফেরতের কারণ'
                                          : 'Reason for Return',
                                      controller: _reasonController,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _showReturnConfirmationDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isDark ? darkShade1 : brightBlue,
                                        side: BorderSide(
                                          color:
                                              isDark ? darkShade3 : deepIndigo,
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        isBangla
                                            ? 'ফেরত সম্পন্ন করুন'
                                            : 'Process Return',
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
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ReturnHistoryPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.history,
                                  color: Colors.white),
                              label: Text(
                                isBangla ? 'ফেরতের ইতিহাস' : 'Return History',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? darkShade2 : deepIndigo,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }
}
