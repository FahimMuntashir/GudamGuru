import 'package:flutter/material.dart';



class HomePage extends StatelessWidget {
  final String companyName;
  const HomePage({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GUDAMGURU'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                companyName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // _buildQuickPanelButton('Add New Product', 'assets/images/add_product.png'),
                // _buildQuickPanelButton('Add New Item', 'assets/images/add_item.png'),
                // _buildQuickPanelButton('Sell Items', 'assets/images/sell_items.png'),
                // _buildQuickPanelButton('Inventory', 'assets/images/inventory.png'),
                // _buildQuickPanelButton('Buy & Sell Reports', 'assets/images/reports.png'),
                // _buildQuickPanelButton('Low Stock Alerts', 'assets/images/low_stock.png'),
                 _buildQuickPanelButton('Add New Product', 'assets/images/logo.png'),
                _buildQuickPanelButton('Add New Item', 'assets/images/logo.png'),
                _buildQuickPanelButton('Sell Items', 'assets/images/logo.png'),
                _buildQuickPanelButton('Inventory', 'assets/images/logo.png'),
                _buildQuickPanelButton('Buy & Sell Reports', 'assets/images/logo.png'),
                _buildQuickPanelButton('Low Stock Alerts', 'assets/images/logo.png'),
              ],
            ),
          ),

          // Overview Panel
           Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildOverviewTile('Total Sales Today', '৳ 0.00'),
                _buildOverviewTile('Total Purchase Today', '৳ 0.00'),
                _buildOverviewTile('Current Stock Value', '৳ 0.00'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildQuickPanelButton(String title, String imagePath) {
    return Column(
      children: [
        Image.asset(imagePath, width: 50, height: 50),
        const SizedBox(height: 5),
        Text(title, textAlign: TextAlign.center),
      ],
    );
  }

  static Widget _buildOverviewTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

Widget _buildTextField(String hint, {bool isPassword = false}) {
  return TextField(
    obscureText: isPassword,
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget _buildButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
}
