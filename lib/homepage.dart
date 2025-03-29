import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'inventory.dart';
import 'lowstock.dart';
import 'newitem.dart';
import 'newproduct.dart';
import 'notes.dart';
import 'profile_page.dart';
import 'providers/product_provider.dart';
import 'providers/user_provider.dart';
import 'reportanalytics.dart';
import 'sell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final productProvider = context.watch<ProductProvider>();
    final stats = productProvider.dashboardStats;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
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
                        userProvider.companyName ?? 'Company Name',
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text('ENG'),
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
                      _buildOverviewTile(
                        'assets/images/taka.png',
                        'Total Sales Today',
                        '৳ ${stats?['total_sales_today']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      _buildOverviewTile(
                        'assets/images/purchase.png',
                        'Total Products',
                        '${stats?['total_products'] ?? 0}',
                      ),
                      _buildOverviewTile(
                        'assets/images/stock.png',
                        'Low Stock Items',
                        '${stats?['low_stock_items'] ?? 0}',
                      ),
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
        unselectedItemColor: Colors.black,
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

  Widget _buildQuickButton(
      String iconPath, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Add New Product':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewProductPage()),
            );
            break;
          case 'Add New Item':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewItemPage()),
            );
            break;
          case 'Sell Items':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SellPage()),
            );
            break;
          case 'Inventory':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InventoryPage()),
            );
            break;
          case 'Buy & Sell Reports':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReportAnalyticsPage()),
            );
            break;
          case 'Low Stock Alerts':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LowStockPage()),
            );
            break;
          case 'Notes':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotesPage()),
            );
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.all(5),
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

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
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    ),
  );
}
