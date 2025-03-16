import 'package:flutter/material.dart';
import 'package:gudam_guru/home.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool isEditing = false;
  List<Map<String, dynamic>> inventoryData = [
    {
      'category': 'Category A',
      'products': [
        {
          'id': '101',
          'name': 'Product 1',
          'quantity': '10',
          'unit': 'KG',
          'price': '50',
          'brand': 'Brand A',
          'stock': '500',
          'lowStock': '5',
          'description': 'Product description',
          'expanded': false
        },
      ]
    },
    {
      'category': 'Category B',
      'products': [
        {
          'id': '102',
          'name': 'Product 2',
          'quantity': '5',
          'unit': 'KG',
          'price': '40',
          'brand': 'Brand B',
          'stock': '200',
          'lowStock': '3',
          'description': 'Another product description',
          'expanded': false
        },
        {
          'id': '103',
          'name': 'Product 3',
          'quantity': '8',
          'unit': 'KG',
          'price': '30',
          'brand': 'Brand C',
          'stock': '300',
          'lowStock': '4',
          'description': 'More product info',
          'expanded': false
        },
      ]
    },
  ];

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
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
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

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                    });
                  },
                  child: Text(
                    isEditing ? 'Save' : 'Edit',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                // Inventory List by Category
                _buildInventoryList(),
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
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

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildInventoryList() {
    return Column(
      children: inventoryData.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                category['category'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: category['products'].map<Widget>((product) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Column(
                    children: [
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text('${product['id']} - ${product['name']}'),
                        trailing: Text(
                            'Quantity: ${product['quantity']} ${product['unit']}'),
                        onTap: () {
                          setState(() {
                            product['expanded'] =
                                !(product['expanded'] ?? false);
                          });
                        },
                      ),
                      if (product['expanded'] ?? false)
                        _buildExpandedDetails(product),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(10),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Product ID: ${product['id']}  |  Quantity: ${product['quantity']} ${product['unit']}'),
            Text(
                'Product Name: ${product['name']}  |  Price/unit: ${product['price']}'),
            Text(
                'Brand Name: ${product['brand']}  |  Total Stock Value: ${product['stock']}'),
            Text('Set Low Stock Alert: ${product['lowStock']}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(product['description'],
                  style: const TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoRow(String leftLabel, String rightLabel, String unit) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
          child: Text(leftLabel,
              style: const TextStyle(fontWeight: FontWeight.bold))),
      if (rightLabel.isNotEmpty)
        Expanded(
          child: Row(
            children: [
              Text(rightLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (unit.isNotEmpty) Text(' $unit'),
            ],
          ),
        ),
    ],
  );
}
