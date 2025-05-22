import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'header&nav.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';
// import 'UserSession.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'invoices.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> cart = [];
  Map<String, dynamic>? selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Widget _buildQuickActions() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Expanded(
  //         child: _buildQuickActionButton(
  //             'assets/images/cam.png', 'Take a Picture'),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: _buildQuickActionButton(
  //             'assets/images/barcode.png', 'Scan Barcode'),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildQuickActionButton(String iconPath, String label) {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 5,
  //           spreadRadius: 2,
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Image.asset(iconPath, width: 40, height: 40),
  //         const SizedBox(height: 5),
  //         Text(label,
  //             style:
  //                 const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _loadProducts() async {
    allProducts = await DatabaseHelper().getAllProducts();
    setState(() {});
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => filteredProducts = []);
    } else {
      setState(() {
        filteredProducts = allProducts
            .where((p) =>
                p['name'].toLowerCase().contains(query.toLowerCase()) ||
                p['product_id'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product;
      _searchController.clear();
      filteredProducts = [];
    });
  }

  void _addToCart() {
    final isBangla = context.read<LanguageProvider>().isBangla;

    if (selectedProduct == null ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty) return;

    final int qty = int.tryParse(_quantityController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int availableStock = selectedProduct!['quantity'];

    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBangla
                ? 'স্টকে মাত্র $availableStock টি আছে!'
                : 'Only $availableStock in stock!',
          ),
        ),
      );
      return;
    }

    setState(() {
      cart.add({
        'product_id': selectedProduct!['product_id'],
        'name': selectedProduct!['name'],
        'unit': selectedProduct!['unit'],
        'price': price,
        'quantity': qty,
      });
      selectedProduct = null;
      _priceController.clear();
      _quantityController.clear();
    });
  }

  void _updateQuantity(int index, int change) {
    final isBangla = context.read<LanguageProvider>().isBangla;

    final productId = cart[index]['product_id'];
    final currentQty = cart[index]['quantity'];
    final availableQty = allProducts.firstWhere(
      (p) => p['product_id'] == productId,
      orElse: () => {'quantity': 0},
    )['quantity'];

    if (change > 0 && currentQty + change > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBangla
                ? 'স্টকে মাত্র $availableQty টি আছে!'
                : 'Only $availableQty available in stock!',
          ),
        ),
      );
      return;
    }

    setState(() {
      cart[index]['quantity'] += change;
      if (cart[index]['quantity'] <= 0) {
        cart.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  // Future<void> _confirmSell() async {
  //   final db = DatabaseHelper();

  //   // Generate invoice number and timestamps
  //   String invoiceNumber = 'INV${DateTime.now().millisecondsSinceEpoch}';
  //   String timeOnly = DateFormat('HH:mm:ss').format(DateTime.now());
  //   String dateOnly = DateFormat('yyyy-MM-dd').format(DateTime.now());

  //   for (var item in cart) {
  //     String productId = item['product_id'];
  //     int qtyToDeduct = item['quantity'];
  //     double unitPrice = item['price'];

  //     List<Map<String, dynamic>> stockListRaw =
  //         await db.getStockEntriesForProduct(productId);
  //     List<Map<String, dynamic>> stockList =
  //         List<Map<String, dynamic>>.from(stockListRaw);

  //     // Sort FIFO (oldest stock first)
  //     stockList.sort((a, b) {
  //       int dateCompare = DateTime.parse(a['date_added'])
  //           .compareTo(DateTime.parse(b['date_added']));
  //       return dateCompare != 0 ? dateCompare : a['id'].compareTo(b['id']);
  //     });

  //     double totalCost = 0.0;
  //     int totalQty = qtyToDeduct;

  //     // Deduct stock using FIFO and compute total cost
  //     for (var stock in stockList) {
  //       if (qtyToDeduct == 0) break;

  //       int availableQty = stock['quantity'];
  //       double price = stock['purchase_price'];
  //       int consumeQty =
  //           qtyToDeduct >= availableQty ? availableQty : qtyToDeduct;

  //       totalCost += consumeQty * price;

  //       await db.updateStockEntryQuantity(
  //           stock['id'], availableQty - consumeQty);
  //       qtyToDeduct -= consumeQty;
  //     }

  //     await db.decreaseProductQuantity(productId, item['quantity']);

  //     // ✅ Compute weighted average purchase price
  //     double purchasePrice = totalQty > 0 ? totalCost / totalQty : 0.0;

  //     await db.insertSale({
  //       'invoice_number': invoiceNumber,
  //       'date_sold': dateOnly,
  //       'time_sold': timeOnly,
  //       'product_id': productId,
  //       'name': item['name'],
  //       'quantity': item['quantity'],
  //       'unit_price': unitPrice,
  //       'purchase_price': purchasePrice,
  //       'total_price': item['quantity'] * unitPrice,
  //       'stock_entry_id': stock['id'],
  //     });
  //   }

  //   setState(() => cart.clear());

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Sale completed and inventory updated!")),
  //   );
  // }
  Future<void> _confirmSell() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final bool isBangla = languageProvider.isBangla;

    final db = DatabaseHelper();

    String invoiceNumber = 'INV${DateTime.now().millisecondsSinceEpoch}';
    String timeOnly = DateFormat('HH:mm:ss').format(DateTime.now());
    String dateOnly = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var item in cart) {
      String productId = item['product_id'];
      int qtyToDeduct = item['quantity'];
      double unitPrice = item['price'];

      List<Map<String, dynamic>> stockListRaw =
          await db.getStockEntriesForProduct(productId);
      List<Map<String, dynamic>> stockList =
          List<Map<String, dynamic>>.from(stockListRaw);

      // Sort FIFO (oldest first)
      stockList.sort((a, b) {
        int dateCompare = DateTime.parse(a['date_added'])
            .compareTo(DateTime.parse(b['date_added']));
        return dateCompare != 0 ? dateCompare : a['id'].compareTo(b['id']);
      });

      for (var stock in stockList) {
        if (qtyToDeduct == 0) break;

        int availableQty = stock['quantity'];
        double purchasePrice = stock['purchase_price'];
        int consumeQty =
            qtyToDeduct >= availableQty ? availableQty : qtyToDeduct;

        // Update stock entry quantity
        await db.updateStockEntryQuantity(
            stock['id'], availableQty - consumeQty);
        qtyToDeduct -= consumeQty;

        // Insert sale for this batch
        await db.insertSale({
          'invoice_number': invoiceNumber,
          'date_sold': dateOnly,
          'time_sold': timeOnly,
          'product_id': productId,
          'name': item['name'],
          'quantity': consumeQty,
          'unit_price': unitPrice,
          'purchase_price': purchasePrice,
          'total_price': unitPrice * consumeQty,
          'stock_entry_id': stock['id'], //LIFO traceability
        });
      }

      // Update overall product quantity
      await db.decreaseProductQuantity(productId, item['quantity']);
    }

    setState(() => cart.clear());

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBangla
              ? 'বিক্রয় সম্পন্ন হয়েছে এবং ইনভেন্টরি হালনাগাদ হয়েছে!'
              : 'Sale completed and inventory updated!',
        ),
      ),
    );
  }

  void _showSellConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBangla ? "কার্ট খালি!" : "Cart is empty!"),
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
            isBangla ? 'বিক্রয় নিশ্চিত করুন' : 'Confirm Sale',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : deepIndigo,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...cart.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "${item['name']} → ${item['quantity']} × ৳${item['price']} = ৳${(item['quantity'] * item['price']).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )),
                const SizedBox(height: 10),
                Text(
                  "${isBangla ? 'মোট' : 'Total'}: ৳${cart.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']))}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
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
                await _confirmSell();
              },
              child: Text(isBangla ? 'নিশ্চিত করুন' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  TextStyle themedBoldTextStyle({
    required bool isDark,
    double fontSize = 16,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      color: isDark ? Colors.white : deepIndigo,
      fontWeight: weight,
      fontSize: fontSize,
    );
  }

  Widget _buildCartSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : vibrantBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? darkShade3 : deepIndigo,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBangla ? 'কার্ট' : 'CART',
            style: themedBoldTextStyle(
              isDark: isDark,
              fontSize: 18,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: cart.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'],
                      style: themedBoldTextStyle(
                        isDark: isDark,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: isDark ? Colors.white : deepIndigo,
                    ),
                    onPressed: () => _updateQuantity(index, -1),
                  ),
                  Text(
                    '${item['quantity']}',
                    style: themedBoldTextStyle(isDark: isDark),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: isDark ? Colors.white : deepIndigo,
                    ),
                    onPressed: () => _updateQuantity(index, 1),
                  ),
                  Text(
                    '${item['price'] * item['quantity']} TK',
                    style: themedBoldTextStyle(isDark: isDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () => _removeFromCart(index),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBangla ? 'মোট মূল্য' : 'TOTAL PRICE',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  fontSize: 16,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                '৳${cart.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']))}',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  fontSize: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _showSellConfirmationDialog,
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                label: Text(
                  isBangla ? 'বিক্রি নিশ্চিত করুন' : 'Confirm Sell',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? darkShade1 : brightBlue,
                  side: BorderSide(
                    color: isDark ? darkShade3 : deepIndigo,
                    width: 2,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
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
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
          ),
          Column(
            children: [
              buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: isBangla
                              ? 'পণ্যের আইডি বা নাম দিয়ে খুঁজুন'
                              : 'Search Product by ID or Name',
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white : deepIndigo),
                          prefixIcon: Icon(Icons.search,
                              color: isDark ? Colors.white : deepIndigo),
                          filled: true,
                          fillColor: isDark ? darkShade1 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: isDark ? darkShade2 : deepIndigo),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: isDark ? darkShade2 : deepIndigo,
                                width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: isDark ? darkShade3 : brightBlue,
                                width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (filteredProducts.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ListTile(
                              tileColor: isDark
                                  ? darkShade2.withOpacity(0.2)
                                  : vibrantBlue.withOpacity(0.4),
                              title: Text(product['name'],
                                  style: TextStyle(
                                      color:
                                          isDark ? Colors.white : deepIndigo)),
                              subtitle: Text('ID: ${product['product_id']}',
                                  style: TextStyle(
                                      color:
                                          isDark ? Colors.white : deepIndigo)),
                              onTap: () => _selectProduct(product),
                            );
                          },
                        ),
                      const SizedBox(height: 10),
                      if (selectedProduct != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : vibrantBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: isDark ? darkShade3 : deepIndigo,
                                width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${isBangla ? 'নির্বাচিত' : 'Selected'}: ${selectedProduct!['name']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : deepIndigo,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: isBangla
                                      ? 'বিক্রয় মূল্য (প্রতি ইউনিট)'
                                      : 'Selling Price (per unit)',
                                  hintStyle: TextStyle(
                                      color:
                                          isDark ? Colors.white : deepIndigo),
                                  filled: true,
                                  fillColor: isDark ? darkShade1 : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            isDark ? darkShade2 : deepIndigo),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: isDark ? darkShade2 : deepIndigo,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: isDark ? darkShade3 : brightBlue,
                                        width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: isBangla ? 'পরিমাণ' : 'Quantity',
                                  hintStyle: TextStyle(
                                      color:
                                          isDark ? Colors.white70 : deepIndigo),
                                  filled: true,
                                  fillColor: isDark ? darkShade1 : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            isDark ? darkShade2 : deepIndigo),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: isDark ? darkShade2 : deepIndigo,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: isDark ? darkShade3 : brightBlue,
                                        width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _addToCart,
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
                                child: Text(
                                  isBangla ? 'কার্টে যোগ করুন' : 'Add to Cart',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          _buildCartSection(),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const InvoicesPage()),
                              );
                            },
                            icon: const Icon(Icons.receipt_long,
                                color: Colors.white),
                            label: Text(
                              isBangla ? 'চালানসমূহ' : 'Invoices',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? darkShade3 : deepIndigo,
                              side: BorderSide(
                                  color: isDark ? darkShade1 : brightBlue,
                                  width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
