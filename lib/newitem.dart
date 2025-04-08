// import 'package:flutter/material.dart';
// import 'homepage.dart';
// import 'inventory.dart';
// import 'reportanalytics.dart';
// import 'profile.dart';
// import 'UserSession.dart';

// class NewItemPage extends StatefulWidget {
//   const NewItemPage({super.key});

//   @override
//   _NewItemPageState createState() => _NewItemPageState();
// }

// class _NewItemPageState extends State<NewItemPage> {
//   String selectedUnit = 'KG'; // Default unit for Quantity
//   final List<String> unitOptions = [
//     'KG',
//     'Pcs',
//     'Litre',
//     'Dozen',
//     'Bags',
//     'Set',
//     'Gauge',
//     'Packet',
//     'Carton',
//     'SQ Metre',
//     'Metre',
//     'SQ Feet',
//     'Feet',
//     'Inch'
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background Image (Stretched to Full Page)
//           Positioned.fill(
//             child: Container(
//               width: double.infinity,
//               height: double.infinity,
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/images/background.png'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),

//           Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // Header
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 15),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: const BorderRadius.only(
//                             bottomLeft: Radius.circular(5),
//                             bottomRight: Radius.circular(5),
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 5,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Image.asset(
//                               'assets/images/logo.png',
//                               width: 150,
//                             ),
//                             Text(
//                               (UserSession().companyName!),
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Full Container with Buttons & Text Fields
//                       Container(
//                         padding: const EdgeInsets.all(15),
//                         margin: const EdgeInsets.symmetric(horizontal: 20),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFDDE0FF).withOpacity(0.75),
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         child: Column(
//                           children: [
//                             // Quick Actions (Take Picture & Scan Barcode)
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: _buildQuickActionButton(
//                                       'assets/images/cam.png',
//                                       'Take a Picture'),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: _buildQuickActionButton(
//                                       'assets/images/barcode.png',
//                                       'Scan Barcode'),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 10),

//                             // Search Bar
//                             _buildSearchBar(),

//                             const SizedBox(height: 10),

//                             // Input Fields Inside the Container
//                             _buildTextField('Product ID',
//                                 errorText:
//                                     'Not needed if picture/barcode scanned'),
//                             _buildTextField('Product Name'),
//                             _buildTextField('Purchase Price/unit'),

//                             // Quantity with Unit Toggle
//                             Row(
//                               children: [
//                                 Expanded(child: _buildTextField('Quantity')),
//                                 const SizedBox(width: 10),
//                                 DropdownButton<String>(
//                                   value: selectedUnit,
//                                   items: unitOptions.map((String unit) {
//                                     return DropdownMenuItem<String>(
//                                       value: unit,
//                                       child: Text(unit),
//                                     );
//                                   }).toList(),
//                                   onChanged: (String? newValue) {
//                                     setState(() {
//                                       selectedUnit = newValue!;
//                                     });
//                                   },
//                                 ),
//                               ],
//                             ),

//                             _buildTextField('Description', maxLines: 3),

//                             const SizedBox(height: 10),

//                             // Add Item Button
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Color(0xff9b89ff),
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 40, vertical: 15),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                               ),
//                               onPressed: () {},
//                               child: const Text(
//                                 'Add Item',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),

//       // Bottom Navigation Bar
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Color(0xff000000),
//         unselectedItemColor: Colors.black,
//         onTap: (index) {
//           if (index == 0) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const HomePage()),
//             );
//           }
//           if (index == 1) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const InventoryPage()),
//             );
//           }
//           if (index == 2) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => const ReportAnalyticsPage()),
//             );
//           }
//           if (index == 3) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const ProfilePage()),
//             );
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

//   // Search Bar Widget
//   Widget _buildSearchBar() {
//     return TextField(
//       decoration: InputDecoration(
//         filled: true,
//         fillColor: Colors.white,
//         hintText: 'Search',
//         prefixIcon: const Icon(Icons.search),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   // Quick Action Button Widget
//   Widget _buildQuickActionButton(String iconPath, String label) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 5,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(iconPath, width: 40, height: 40),
//           const SizedBox(height: 5),
//           Text(label,
//               style:
//                   const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

// // Text Field Widget with Optional Error Message
//   Widget _buildTextField(String hint, {int maxLines = 1, String? errorText}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (errorText != null)
//             Text(errorText,
//                 style: const TextStyle(color: Colors.red, fontSize: 12)),
//           TextField(
//             maxLines: maxLines,
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: Colors.white,
//               hintText: hint,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'homepage.dart';
// import 'inventory.dart';
// import 'reportanalytics.dart';
// import 'profile.dart';
// import 'UserSession.dart';
// import 'database_helper.dart';

// class NewItemPage extends StatefulWidget {
//   const NewItemPage({super.key});

//   @override
//   _NewItemPageState createState() => _NewItemPageState();
// }

// class _NewItemPageState extends State<NewItemPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();

//   Map<String, dynamic>? selectedProduct;

//   void _searchProduct(String query) async {
//     List<Map<String, dynamic>> allProducts =
//         await DatabaseHelper().getAllProducts();
//     final product = allProducts.firstWhere(
//       (p) =>
//           p['product_id'].toLowerCase() == query.toLowerCase() ||
//           p['name'].toLowerCase() == query.toLowerCase(),
//       orElse: () => {},
//     );

//     if (product.isNotEmpty) {
//       setState(() {
//         selectedProduct = product;
//       });
//     } else {
//       setState(() {
//         selectedProduct = null;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Product not found.")),
//       );
//     }
//   }

//   Future<void> _addItem() async {
//     if (selectedProduct == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("No product selected.")));
//       return;
//     }

//     final String productId = selectedProduct!['product_id'];
//     final double? purchasePrice = double.tryParse(_priceController.text);
//     final int? quantity = int.tryParse(_quantityController.text);
//     final String description = _descriptionController.text;

//     if (purchasePrice == null || quantity == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter valid price and quantity.")),
//       );
//       return;
//     }

//     await DatabaseHelper().insertStockEntry({
//       'product_id': productId,
//       'purchase_price': purchasePrice,
//       'quantity': quantity,
//       'description': description,
//     });

//     await DatabaseHelper().updateProductQuantity(productId, quantity);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Item added successfully!")),
//     );

//     setState(() {
//       _priceController.clear();
//       _quantityController.clear();
//       _descriptionController.clear();
//       _searchController.clear();
//       selectedProduct = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Container(
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/images/background.png'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // Header
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 15),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: const BorderRadius.only(
//                             bottomLeft: Radius.circular(5),
//                             bottomRight: Radius.circular(5),
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 5,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Image.asset('assets/images/logo.png', width: 150),
//                             Text(
//                               (UserSession().companyName ?? ''),
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Container
//                       Container(
//                         padding: const EdgeInsets.all(15),
//                         margin: const EdgeInsets.symmetric(horizontal: 20),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFDDE0FF).withOpacity(0.75),
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildQuickActions(),
//                             const SizedBox(height: 10),
//                             _buildSearchBar(),
//                             const SizedBox(height: 10),
//                             if (selectedProduct != null)
//                               _buildProductDetails(selectedProduct!),
//                             const SizedBox(height: 10),
//                             _buildTextField("New Purchase Price",
//                                 controller: _priceController, isNumber: true),
//                             _buildTextField("Quantity",
//                                 controller: _quantityController,
//                                 isNumber: true),
//                             _buildTextField("Description (Optional)",
//                                 controller: _descriptionController,
//                                 maxLines: 3),
//                             const SizedBox(height: 10),
//                             ElevatedButton(
//                               onPressed: _addItem,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xff9b89ff),
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 40, vertical: 15),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                               ),
//                               child: const Text(
//                                 "Add Item",
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: const Color(0xff000000),
//         unselectedItemColor: Colors.black,
//         onTap: (index) {
//           if (index == 0) {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomePage()));
//           }
//           if (index == 1) {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const InventoryPage()));
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

//   Widget _buildQuickActions() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: _buildQuickActionButton(
//               'assets/images/cam.png', 'Take a Picture'),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _buildQuickActionButton(
//               'assets/images/barcode.png', 'Scan Barcode'),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchBar() {
//     return TextField(
//       controller: _searchController,
//       onSubmitted: _searchProduct,
//       decoration: InputDecoration(
//         hintText: 'Search by Product ID or Name',
//         prefixIcon: const Icon(Icons.search),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   Widget _buildProductDetails(Map<String, dynamic> product) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Name: ${product['name']}'),
//         Text('Brand: ${product['brand_name'] ?? ''}'),
//         Text('Unit: ${product['unit'] ?? ''}'),
//         const Divider(),
//       ],
//     );
//   }

//   Widget _buildQuickActionButton(String iconPath, String label) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 5,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(iconPath, width: 40, height: 40),
//           const SizedBox(height: 5),
//           Text(label,
//               style:
//                   const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(String hint,
//       {TextEditingController? controller,
//       int maxLines = 1,
//       bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         decoration: InputDecoration(
//           filled: true,
//           fillColor: Colors.white,
//           hintText: hint,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'reportanalytics.dart';
import 'profile.dart';
import 'UserSession.dart';
import 'database_helper.dart';

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
                      (UserSession().companyName ?? ''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                            _buildQuickActions(),
                            const SizedBox(height: 10),
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
                                backgroundColor: const Color(0xff9b89ff),
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
                                    fontWeight: FontWeight.bold),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff000000),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _searchProduct,
      decoration: InputDecoration(
        hintText: 'Search by Product ID or Name',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected: ${product['name']} (ID: ${product['product_id']})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text('Brand: ${product['brand_name'] ?? ''}'),
          Text('Unit: ${product['unit'] ?? ''}'),
          const Divider(),
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
      bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
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
      ),
    );
  }
}
