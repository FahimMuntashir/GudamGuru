// import 'package:flutter/material.dart';
// import 'homepage.dart';
// import 'reportanalytics.dart';
// import 'profile.dart';
// import 'UserSession.dart';
// import 'database_helper.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class InventoryPage extends StatefulWidget {
//   const InventoryPage({super.key});

//   @override
//   State<InventoryPage> createState() => _InventoryPageState();
// }

// class _InventoryPageState extends State<InventoryPage> {
//   int _selectedIndex = 1;
//   bool isEditing = false;
//   Map<String, List<Map<String, dynamic>>> groupedProducts = {};
//   final TextEditingController _searchController = TextEditingController();
//   Set<String> expandedProducts = {};
//   Map<String, TextEditingController> quantityControllers = {};
//   Map<String, TextEditingController> priceControllers = {};
//   Map<String, TextEditingController> nameControllers = {};
//   Map<String, TextEditingController> categoryControllers = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchInventory();
//     _searchController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {
//     _fetchInventory(query: _searchController.text);
//   }

//   Future<void> _fetchInventory({String query = ''}) async {
//     List<Map<String, dynamic>> products =
//         await DatabaseHelper().getAllProducts();
//     Map<String, List<Map<String, dynamic>>> grouped = {};

//     for (var product in products) {
//       if (query.isNotEmpty &&
//           !(product['name'].toLowerCase().contains(query.toLowerCase()) ||
//               product['product_id']
//                   .toLowerCase()
//                   .contains(query.toLowerCase()))) {
//         continue;
//       }
//       String category = product['category'] ?? 'Uncategorized';
//       if (!grouped.containsKey(category)) {
//         grouped[category] = [];
//       }
//       grouped[category]!.add(product);

//       quantityControllers[product['product_id']] =
//           TextEditingController(text: product['quantity'].toString());
//       priceControllers[product['product_id']] =
//           TextEditingController(text: product['purchase_price'].toString());
//       nameControllers[product['product_id']] =
//           TextEditingController(text: product['name']);
//       categoryControllers[product['product_id']] =
//           TextEditingController(text: category);
//     }

//     setState(() {
//       groupedProducts = grouped;
//     });
//   }

//   Future<void> _saveEdits() async {
//     for (var products in groupedProducts.values) {
//       for (var product in products) {
//         final String id = product['product_id'];
//         final int quantity =
//             int.tryParse(quantityControllers[id]?.text ?? '') ??
//                 product['quantity'];
//         final double price =
//             double.tryParse(priceControllers[id]?.text ?? '') ??
//                 product['purchase_price'];
//         final String name = nameControllers[id]?.text ?? product['name'];
//         final String newCategory =
//             categoryControllers[id]?.text ?? product['category'];

//         await DatabaseHelper().updateProduct(
//           id,
//           {
//             'name': name,
//             'quantity': quantity,
//             'purchase_price': price,
//             'category': newCategory
//           },
//         );
//       }
//     }
//     _fetchInventory();
//   }

//   Future<void> _exportAsPdf() async {
//     final pdf = pw.Document();

//     groupedProducts.forEach((category, products) {
//       pdf.addPage(
//         pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(category,
//                   style: pw.TextStyle(
//                       fontSize: 18, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),
//               ...products.map((product) => pw.Container(
//                     margin: const pw.EdgeInsets.only(bottom: 10),
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('Product ID: ${product['product_id']}'),
//                         pw.Text('Name: ${product['name']}'),
//                         pw.Text('Category: ${product['category']}'),
//                         pw.Text(
//                             'Purchase Price: ৳${product['purchase_price']}'),
//                         pw.Text('Quantity: ${product['quantity']}'),
//                         if (product['low_stock_alert'] != null)
//                           pw.Text(
//                               'Low Stock Alert: ${product['low_stock_alert']}'),
//                         if ((product['description'] ?? '').isNotEmpty)
//                           pw.Text('Description: ${product['description']}'),
//                       ],
//                     ),
//                   ))
//             ],
//           ),
//         ),
//       );
//     });

//     await Printing.layoutPdf(
//         onLayout: (PdfPageFormat format) async => pdf.save());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(children: [
//         Positioned.fill(
//           child: Container(
//             decoration: BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/background.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),
//         Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 15),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: const BorderRadius.only(
//                           bottomLeft: Radius.circular(5),
//                           bottomRight: Radius.circular(5),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 5,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Image.asset('assets/images/logo.png', width: 150),
//                           Text(
//                             (UserSession().companyName ?? ''),
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(child: _buildSearchBar()),
//                           TextButton(
//                             onPressed: () async {
//                               if (isEditing) await _saveEdits();
//                               setState(() => isEditing = !isEditing);
//                             },
//                             child: Text(
//                               isEditing ? 'SAVE' : 'EDIT',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     _buildGroupedInventoryList(),
//                     Padding(
//                       padding: const EdgeInsets.only(right: 20.0, bottom: 10),
//                       child: Align(
//                         alignment: Alignment.centerRight,
//                         child: FloatingActionButton(
//                           mini: true,
//                           onPressed: _exportAsPdf,
//                           child: const Icon(Icons.picture_as_pdf),
//                           tooltip: 'Export as PDF',
//                           backgroundColor:
//                               const Color.fromARGB(255, 182, 155, 229),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ]),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Colors.green,
//         unselectedItemColor: Colors.black,
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           if (index == 0) {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomePage()));
//           }
//           if (index == 2) {
//             Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => const ReportAnalyticsPage()));
//           }
//           if (index == 3) {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const ProfilePage()));
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.inventory), label: 'Inventory'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.bar_chart), label: 'Report & Analytics'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return TextField(
//       controller: _searchController,
//       decoration: InputDecoration(
//         hintText: 'Search by name or ID',
//         prefixIcon: const Icon(Icons.search),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   Widget _buildGroupedInventoryList() {
//     List<Widget> widgets = [];
//     groupedProducts.forEach((category, products) {
//       widgets.add(
//         Container(
//           padding: const EdgeInsets.all(15),
//           margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//           decoration: BoxDecoration(
//             color: const Color(0xFFDDE0FF).withOpacity(0.75),
//             borderRadius: BorderRadius.circular(5),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 category,
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               ...products.map(_buildProductTile).toList(),
//             ],
//           ),
//         ),
//       );
//     });
//     return Column(children: widgets);
//   }

//   Widget _buildProductTile(Map<String, dynamic> product) {
//     final String id = product['product_id'];
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Column(
//         children: [
//           ListTile(
//             tileColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             title: Text('${product['product_id']} - ${product['name']}'),
//             trailing:
//                 Text('Qty: ${product['quantity']} ${product['unit'] ?? ''}'),
//             onTap: () {
//               setState(() {
//                 if (expandedProducts.contains(id)) {
//                   expandedProducts.remove(id);
//                 } else {
//                   expandedProducts.add(id);
//                 }
//               });
//             },
//           ),
//           if (expandedProducts.contains(id))
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     isEditing
//                         ? TextField(
//                             controller: nameControllers[id],
//                             decoration: const InputDecoration(
//                                 labelText: 'Product Name'),
//                           )
//                         : Text('Name: ${product['name']}'),
//                     isEditing
//                         ? TextField(
//                             controller: categoryControllers[id],
//                             decoration:
//                                 const InputDecoration(labelText: 'Category'),
//                           )
//                         : Text('Category: ${product['category']}'),
//                     Text('Brand: ${product['brand_name'] ?? ''}'),
//                     Text('Unit: ${product['unit'] ?? ''}'),
//                     isEditing
//                         ? TextField(
//                             controller: priceControllers[id],
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                                 labelText: 'Purchase Price'),
//                           )
//                         : Text('Purchase Price: ৳${product['purchase_price']}'),
//                     isEditing
//                         ? TextField(
//                             controller: quantityControllers[id],
//                             keyboardType: TextInputType.number,
//                             decoration:
//                                 const InputDecoration(labelText: 'Quantity'),
//                           )
//                         : Text('Quantity: ${product['quantity']}'),
//                     if (product['low_stock_alert'] != null)
//                       Text('Low Stock Alert: ${product['low_stock_alert']}'),
//                     if ((product['description'] ?? '').isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8),
//                         child: Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: Colors.blue[100],
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                           child: Text(product['description'],
//                               style: const TextStyle(color: Colors.black54)),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             )
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'reportanalytics.dart';
import 'profile.dart';
import 'UserSession.dart';
import 'database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _selectedIndex = 1;
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

        String initialDate =
            (product['date_added'] as String?)?.substring(0, 10) ?? 'N/A';

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
                pw.Text('Total Stock Value: ৳${totalValue.toStringAsFixed(2)}'),
                pw.SizedBox(height: 5),
                pw.Text('Stock History:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Bullet(
                    text:
                        'Purchase price: ৳${product['purchase_price']}  quantity $initialQty ($initialDate)'),
                ...stockEntries.map((entry) => pw.Bullet(
                    text:
                        'Purchase price: ৳${entry['purchase_price']}  quantity ${entry['quantity']} (${entry['date_added'].substring(0, 10)})')),
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
      body: Stack(children: [
        Positioned.fill(
          child: Container(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    UserSession().companyName ?? 'My Inventory',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
                              const Color.fromARGB(255, 182, 155, 229),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name or ID',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            color: const Color(0xFFDDE0FF).withOpacity(0.75),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...products.map(_buildProductTile).toList(),
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
            title: Text('${product['product_id']} - ${product['name']}'),
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
                String initialDate =
                    (product['date_added'] as String?)?.substring(0, 10) ??
                        'N/A';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditing
                            ? TextField(
                                controller: nameControllers[id],
                                decoration: const InputDecoration(
                                    labelText: 'Product Name'),
                              )
                            : Text('Name: ${product['name']}'),
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
                        Text(
                          'Purchase price: ৳${product['purchase_price']}  quantity $initialQty ($initialDate)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
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
