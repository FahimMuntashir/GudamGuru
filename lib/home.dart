import 'package:flutter/material.dart';
import 'package:gudam_guru/inventory.dart';
import 'package:gudam_guru/newitem.dart';
import 'package:gudam_guru/reportanalytics.dart';
import 'package:gudam_guru/sell.dart';

import 'newproduct.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildQuickButton('assets/icons/newProduct.png',
                              'Add New Product', context),
                          _buildQuickButton('assets/icons/addItem.png',
                              'Add New Item', context),
                          _buildQuickButton('assets/icons/sell_items.png',
                              'Sell Items', context),
                          _buildQuickButton('assets/icons/inventory.png',
                              'Inventory', context),
                          _buildQuickButton('assets/icons/analysis.png',
                              'Buy & Sell Reports', context),
                          _buildQuickButton('assets/icons/alert.png',
                              'Low Stock Alerts', context),
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
                      _buildOverviewTile('assets/icons/taka.png',
                          'Total Sales Today', '৳ 0.00'),
                      _buildOverviewTile('assets/icons/purchase.png',
                          'Total Purchase Today', '৳ 0.00'),
                      _buildOverviewTile('assets/icons/stock.png',
                          'Current Stock Value', '৳ 0.00'),
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
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const NewProductPage()), // Fix the class name
        );
      } else if (label == 'Inventory') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const InventoryPage()), // Fix applied here
        );
      }
      else if (label == 'Add New Item') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NewItemPage()), // Fix applied here
        );
      }
      else if (label == 'Buy & Sell Reports') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NewItemPage()), // Fix applied here
        );
      }
        else if (label == 'Sell Items') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const SellPage()), // Fix applied here
        );
      }
    },
    child: Column(
      children: [
        Container(
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
            children: [
              Image.asset(iconPath, width: 40, height: 40),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
