import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'header&nav.dart';
import 'providers/theme_provider.dart';
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

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product;
      _searchController.clear();
      searchSuggestions = [];
    });
  }

  Future<void> _addItem() async {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No product selected.")));
      return;
    }

    final String productId = selectedProduct!['product_id'];
    final double? purchasePrice = double.tryParse(_priceController.text);
    final int? quantity = int.tryParse(_quantityController.text);
    final String description = _descriptionController.text;

    if (purchasePrice == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid price and quantity.")),
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
      const SnackBar(content: Text("Item added successfully!")),
    );

    setState(() {
      _priceController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _searchController.clear();
      selectedProduct = null;
    });
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
                                blurRadius: 10)
                          ],
                          border: Border.all(
                              color: isDark ? Colors.white : brightBlue,
                              width: 2),
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
                            _buildTextField("New Purchase Price",
                                controller: _priceController, isNumber: true),
                            _buildTextField("Quantity",
                                controller: _quantityController,
                                isNumber: true),
                            _buildTextField("Description (Optional)",
                                controller: _descriptionController,
                                maxLines: 3),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _addItem,
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
                              child: const Text(
                                "Add Item",
                                style: TextStyle(
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
      bottomNavigationBar: BottomNav(context, null),
    );
  }

  Widget _buildSearchBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return TextField(
      controller: _searchController,
      onChanged: _searchProduct,
      decoration: InputDecoration(
        hintText: 'Search by Product ID or Name',
        hintStyle: TextStyle(color: isDark ? Colors.white : deepIndigo),
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
              color: isDark ? darkShade3 : Color.fromARGB(255, 13, 0, 255),
              width: 2),
        ),
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> product) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

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
                    color: isDark ? darkShade3 : deepIndigo, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${product['name']}   (ID: ${product['product_id']})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text('Brand: ${product['brand_name'] ?? ''}'),
                  Text('Unit: ${product['unit'] ?? ''}'),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon:
                    Icon(Icons.cancel, color: isDark ? darkShade3 : deepIndigo),
                tooltip: 'Unselect',
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
                color: isDark ? darkShade3 : Color.fromARGB(255, 13, 0, 255),
                width: 2),
          ),
        ),
      ),
    );
  }
}
