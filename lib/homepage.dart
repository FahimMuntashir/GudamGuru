import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'UserSession.dart';
import 'database_helper.dart';
import 'inventory.dart';
import 'lowstock.dart';
import 'newitem.dart';
import 'newproduct.dart';
import 'notes.dart';
import 'profile.dart';
import 'providers/theme_provider.dart';
import 'reportanalytics.dart';
import 'sell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  double _totalStockValue = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalStockValue();
  }

  Future<void> _calculateTotalStockValue() async {
    final products = await DatabaseHelper().getAllProducts();
    double total = 0.0;

    for (var product in products) {
      final stockEntries = await DatabaseHelper()
          .getStockEntriesForProduct(product['product_id']);

      int restockQty = stockEntries.fold(
          0, (sum, entry) => sum + (entry['quantity'] as int));
      int initialQty = product['quantity'] - restockQty;

      total += (initialQty * product['purchase_price']) +
          stockEntries.fold(
            0.0,
            (sum, entry) => sum + (entry['purchase_price'] * entry['quantity']),
          );
    }

    setState(() {
      _totalStockValue = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Add this image in your assets folder
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.2),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Header (Contained in White Box at the Top, Now Scrollable)
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
                      Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                      ),
                      Text(
                        (UserSession().companyName!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Panel (Contained in Colored Box)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0FF).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick panel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Action Buttons
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        children: [
                          _buildQuickButton('assets/images/newProduct.png',
                              'Add New Product', context),
                          _buildQuickButton('assets/images/addItem.png',
                              'Add New Item', context),
                          _buildQuickButton(
                              'assets/images/sell.png', 'Sell Items', context),
                          _buildQuickButton(
                              'assets/images/stock.png', 'Inventory', context),
                          _buildQuickButton('assets/images/analysis.png',
                              'Buy & Sell Reports', context),
                          _buildQuickButton('assets/images/alert.png',
                              'Low Stock Alerts', context),
                          _buildQuickButton(
                              'assets/images/notes.png', 'Notes', context),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Overview Panel (Contained in Colored Box)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0FF).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildOverviewTile('assets/images/taka.png',
                          'Total Sales Today', '৳ 0.00'),
                      _buildOverviewTile('assets/images/purchase.png',
                          'Total Purchase Today', '৳ 0.00'),
                      _buildOverviewTile(
                          'assets/images/stock.png',
                          'Current Stock Value',
                          '৳ ${_totalStockValue.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor:
            themeProvider.isDarkMode ? Colors.white70 : Colors.black,
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
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
}

// FINAL FIX: Prevent Right Overflow in Overview Panel
Widget _buildOverviewTile(String iconPath, String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
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
      child: Row(
        children: [
          Image.asset(iconPath, width: 30, height: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    ),
  );
}

//quicl panel
Widget _buildQuickButton(String iconPath, String label, BuildContext context) {
  return GestureDetector(
    onTap: () {
      if (label == 'Add New Product') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NewProductPage()));
      } else if (label == 'Add New Item') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NewItemPage()));
      } else if (label == 'Sell Items') {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const SellPage()));
      } else if (label == 'Inventory') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const InventoryPage()));
      } else if (label == 'Buy & Sell Reports') {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ReportAnalyticsPage()));
      } else if (label == 'Low Stock Alerts') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const LowStockPage()));
      } else if (label == 'Notes') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NotesPage()));
      }
    },
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 40, height: 40),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
