import 'package:flutter/material.dart';
import 'header&nav.dart';
// import 'UserSession.dart';
import 'database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool isEditing = false;
  Map<String, List<Map<String, dynamic>>> groupedProducts = {};
  final TextEditingController _searchController = TextEditingController();
  Set<String> expandedProducts = {};
  Map<String, TextEditingController> quantityControllers = {};
  Map<String, TextEditingController> priceControllers = {};
  Map<String, TextEditingController> nameControllers = {};
  Map<String, TextEditingController> categoryControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _fetchInventory(query: _searchController.text);
  }

  Future<void> _fetchInventory({String query = ''}) async {
    List<Map<String, dynamic>> products =
        await DatabaseHelper().getAllProducts();
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var product in products) {
      if (query.isNotEmpty &&
          !(product['name'].toLowerCase().contains(query.toLowerCase()) ||
              product['product_id']
                  .toLowerCase()
                  .contains(query.toLowerCase()))) {
        continue;
      }
      String category = product['category'] ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(product);

      quantityControllers[product['product_id']] =
          TextEditingController(text: product['quantity'].toString());
      priceControllers[product['product_id']] =
          TextEditingController(text: product['purchase_price'].toString());
      nameControllers[product['product_id']] =
          TextEditingController(text: product['name']);
      categoryControllers[product['product_id']] =
          TextEditingController(text: category);
    }

    setState(() {
      groupedProducts = grouped;
    });
  }

  Future<void> _saveEdits() async {
    for (var products in groupedProducts.values) {
      for (var product in products) {
        final String id = product['product_id'];
        final int quantity =
            int.tryParse(quantityControllers[id]?.text ?? '') ??
                product['quantity'];
        final double price =
            double.tryParse(priceControllers[id]?.text ?? '') ??
                product['purchase_price'];
        final String name = nameControllers[id]?.text ?? product['name'];
        final String newCategory =
            categoryControllers[id]?.text ?? product['category'];

        await DatabaseHelper().updateProduct(
          id,
          {
            'name': name,
            'quantity': quantity,
            'purchase_price': price,
            'category': newCategory
          },
        );
      }
    }
    _fetchInventory();
  }

  Future<void> _exportAsPdf() async {
    final pdf = pw.Document();

    for (var category in groupedProducts.keys) {
      for (var product in groupedProducts[category]!) {
        List<Map<String, dynamic>> stockEntries =
            List<Map<String, dynamic>>.from(await DatabaseHelper()
                .getStockEntriesForProduct(product['product_id']));

        int totalRestockQty =
            stockEntries.fold(0, (sum, e) => sum + (e['quantity'] as int));
        int initialQty = product['quantity'] - totalRestockQty;

        double totalValue = (product['purchase_price'] * initialQty) +
            stockEntries.fold(
                0.0, (sum, e) => sum + (e['purchase_price'] * e['quantity']));

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(category,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Product ID: ${product['product_id']}'),
                pw.Text('Name: ${product['name']}'),
                pw.Text('Category: ${product['category']}'),
                pw.Text(
                    'Quantity: ${product['quantity']} ${product['unit'] ?? ''}'),
                pw.Text(
                    'Total Stock Value: TK${totalValue.toStringAsFixed(2)}'),
                pw.SizedBox(height: 5),
                pw.Text('Stock History:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...stockEntries.map((entry) => pw.Bullet(
                    text:
                        'Purchase price: TK${entry['purchase_price']}  quantity ${entry['quantity']} (${entry['date_added'].substring(0, 10)})')),
              ],
            ),
          ),
        );
      }
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(240, 255, 255, 255),
      body: Stack(children: [
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
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildSearchBar()),
                          TextButton(
                            onPressed: () async {
                              if (isEditing) await _saveEdits();
                              setState(() => isEditing = !isEditing);
                            },
                            child: Text(
                              isEditing ? 'SAVE' : 'EDIT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEditing ? brightBlue : deepIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildGroupedInventoryList(),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _exportAsPdf,
                          child: const Icon(Icons.picture_as_pdf),
                          tooltip: 'Export as PDF',
                          backgroundColor:
                              const Color.fromARGB(255, 160, 166, 252),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ]),
      bottomNavigationBar: BottomNav(context, 1),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name or ID',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: deepIndigo, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: deepIndigo, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brightBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildGroupedInventoryList() {
    List<Widget> widgets = [];
    groupedProducts.forEach((category, products) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: vibrantBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              ...products.map((product) {
                final String id = product['product_id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: expandedProducts.contains(id)
                          ? brightBlue
                          : deepIndigo,
                      width: 2,
                    ),
                  ),
                  child: _buildProductTile(product),
                );
              }),
            ],
          ),
        ),
      );
    });
    return Column(children: widgets);
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    final String id = product['product_id'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              '${product['product_id']} - ${product['name']}',
              style: TextStyle(
                fontWeight: expandedProducts.contains(id)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing:
                Text('Qty: ${product['quantity']} ${product['unit'] ?? ''}'),
            onTap: () {
              setState(() {
                if (expandedProducts.contains(id)) {
                  expandedProducts.remove(id);
                } else {
                  expandedProducts.add(id);
                }
              });
            },
          ),
          if (expandedProducts.contains(id))
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getStockEntriesForProduct(id),
              builder: (context, snapshot) {
                final entries =
                    List<Map<String, dynamic>>.from(snapshot.data ?? []);
                int totalRestock =
                    entries.fold(0, (sum, e) => sum + (e['quantity'] as int));
                int initialQty = product['quantity'] - totalRestock;
                double totalValue = (product['purchase_price'] * initialQty) +
                    entries.fold(
                        0.0,
                        (sum, e) =>
                            sum + (e['purchase_price'] * e['quantity']));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        top: 0, bottom: 10, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // isEditing
                        //     ? TextField(
                        //         controller: nameControllers[id],
                        //         decoration: const InputDecoration(
                        //             labelText: 'Product Name'),
                        //       )
                        //     : Text('Name: ${product['name']}'),
                        isEditing
                            ? TextField(
                                controller: categoryControllers[id],
                                decoration: const InputDecoration(
                                    labelText: 'Category'),
                              )
                            : Text('Category: ${product['category']}'),
                        Text('Brand: ${product['brand_name'] ?? ''}'),
                        Text('Unit: ${product['unit'] ?? ''}'),
                        isEditing
                            ? TextField(
                                controller: quantityControllers[id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Quantity'),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Quantity: ${product['quantity']}'),
                                  Text(
                                    'Total Stock Value: ৳${totalValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                        const Divider(),
                        const Text("Stock History:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 5),
                        ...entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Purchase price: ৳${entry['purchase_price']}  quantity ${entry['quantity']} (${entry['date_added'].substring(0, 10)})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}
