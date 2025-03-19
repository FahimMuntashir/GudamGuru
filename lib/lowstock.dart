import 'package:flutter/material.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'reportanalytics.dart';
import 'profile.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  _LowStockPageState createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  bool sortAscending = true;
  List<Map<String, dynamic>> lowStockProducts = [
    {'name': 'Product A', 'stock': 3, 'threshold': 5},
    {'name': 'Product B', 'stock': 1, 'threshold': 3},
    {'name': 'Product C', 'stock': 2, 'threshold': 4},
  ];

  List<Map<String, dynamic>> outOfStockProducts = [
    {'name': 'Product X'},
    {'name': 'Product Y'},
  ];

  void _sortStock() {
    setState(() {
      if (sortAscending) {
        lowStockProducts.sort((a, b) => a['stock'].compareTo(b['stock']));
      } else {
        lowStockProducts.sort((a, b) => b['stock'].compareTo(a['stock']));
      }
      sortAscending = !sortAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
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
                            Image.asset(
                              'assets/images/logo.png',
                              width: 150,
                            ),
                            const Text(
                              'Company name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sorting Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sort by Stock Level:'),
                            IconButton(
                              icon: Icon(sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward),
                              onPressed: _sortStock,
                            ),
                          ],
                        ),
                      ),

                      // Low Stock Alerts
                      _buildSectionTitle('Low Stock Alerts'),
                      _buildLowStockList(),

                      // Out of Stock Alerts
                      _buildSectionTitle('Out of Stock Alerts'),
                      _buildOutOfStockList(),

                      // Stock Report
                      _buildSectionTitle('Stock Report'),
                      _buildStockReport(),

                      // Export Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          onPressed: () {}, // Implement export logic
                          child: const Text(
                              'Export Stock Alert Report (📤 PDF/Excel)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff000000),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InventoryPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReportAnalyticsPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
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

  Widget _buildLowStockList() {
    return Column(
      children: lowStockProducts.map((product) {
        return ListTile(
          title: Text('${product['name']} - ${product['stock']} left'),
          subtitle: Text('Reorder at ${product['threshold']}'),
          trailing: Icon(Icons.warning, color: Colors.orange),
        );
      }).toList(),
    );
  }

  Widget _buildOutOfStockList() {
    return Column(
      children: outOfStockProducts.map((product) {
        return ListTile(
          title: Text('${product['name']} - Out of Stock'),
          trailing: Icon(Icons.error, color: Colors.red),
        );
      }).toList(),
    );
  }

  Widget _buildStockReport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
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
          children: const [
            ListTile(title: Text('Current Stock Value: 500,000 TK')),
            ListTile(
                title: Text('Fastest Moving Products: Product A, Product C')),
            ListTile(
                title: Text('Slow-Moving or Dead Stock: Product X, Product Y')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
