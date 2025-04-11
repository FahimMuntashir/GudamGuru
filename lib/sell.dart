
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'reportanalytics.dart';
import 'profile.dart';
import 'UserSession.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildQuickActionButton(
              'assets/images/cam.png', 'Take a Picture'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
              'assets/images/barcode.png', 'Scan Barcode'),
        ),
      ],
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
    if (selectedProduct == null ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty) return;

    final int qty = int.tryParse(_quantityController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int availableStock = selectedProduct!['quantity'];

    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only $availableStock in stock!")),
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
    final productId = cart[index]['product_id'];
    final currentQty = cart[index]['quantity'];
    final availableQty = allProducts.firstWhere(
      (p) => p['product_id'] == productId,
      orElse: () => {'quantity': 0},
    )['quantity'];

    if (change > 0 && currentQty + change > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only $availableQty available in stock!")),
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

  Future<void> _confirmSell() async {
    final db = DatabaseHelper();

    for (var item in cart) {
      String productId = item['product_id'];
      int qtyToDeduct = item['quantity'];
      double unitPrice = item['price'];

      List<Map<String, dynamic>> stockListRaw =
          await db.getStockEntriesForProduct(productId);
      List<Map<String, dynamic>> stockList =
          List<Map<String, dynamic>>.from(stockListRaw);

      // ✅ Sort by date_added ASC and then by ID ASC (FIFO fallback)
      stockList.sort((a, b) {
        int dateCompare = DateTime.parse(a['date_added'])
            .compareTo(DateTime.parse(b['date_added']));
        if (dateCompare != 0) return dateCompare;
        return a['id'].compareTo(b['id']);
      });

      for (var stock in stockList) {
        if (qtyToDeduct == 0) break;
        int availableQty = stock['quantity'];
        int consumeQty =
            qtyToDeduct >= availableQty ? availableQty : qtyToDeduct;

        await db.updateStockEntryQuantity(
            stock['id'], availableQty - consumeQty);
        qtyToDeduct -= consumeQty;
      }

      await db.decreaseProductQuantity(productId, item['quantity']);

      await db.insertSale({
        'product_id': productId,
        'quantity': item['quantity'],
        'unit_price': unitPrice,
        'total_price': item['quantity'] * unitPrice,
        'date_sold': DateTime.now().toString(),
        'user_id': UserSession().userId,
      });
    }

    setState(() => cart.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sale completed and inventory updated!")),
    );
  }

  Future<void> _exportAsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('GudamGuru - Sales Receipt',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.SizedBox(height: 10),
            ...cart.map((item) => pw.Text(
                '${item['name']} - Qty: ${item['quantity']} × ৳${item['price']} = ৳${(item['quantity'] * item['price']).toStringAsFixed(2)}')),
            pw.Divider(),
            pw.Text(
              'Total: ৳${cart.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']))}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            )
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Widget _buildCartSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE0FF).withOpacity(0.75),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CART',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: cart.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item['name'])),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _updateQuantity(index, -1),
                  ),
                  Text('${item['quantity']}'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _updateQuantity(index, 1),
                  ),
                  Text('${item['price'] * item['quantity']} TK'),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
              const Text('TOTAL PRICE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '৳${cart.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']))}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _confirmSell,
                icon: const Icon(Icons.check),
                label: const Text('Confirm Sell'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      UserSession().companyName ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search Product by ID or Name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
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
                              tileColor: Colors.white,
                              title: Text(product['name']),
                              subtitle: Text('ID: ${product['product_id']}'),
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
                            color: const Color(0xFFDDE0FF).withOpacity(0.75),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected: ${selectedProduct!['name']}'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price (per unit)',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _addToCart,
                                child: const Text('Add to Cart'),
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
                            icon: const Icon(
                                Icons.receipt_long), // Invoice-style icon
                            label: const Text("Invoices"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff9b89ff),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
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
}
