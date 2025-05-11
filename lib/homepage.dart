import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// import 'UserSession.dart';
import 'database_helper.dart';
// import 'package:provider/provider.dart';
import 'header&nav.dart';
import 'inventory.dart';
import 'lowstock.dart';
import 'newitem.dart';
import 'newproduct.dart';
import 'notes.dart';
// import 'providers/theme_provider.dart';
import 'reportanalytics.dart';
import 'return_item.dart';
import 'sell.dart';

const Color deepIndigo = Color(0xFF211C84); // Primary
const Color vibrantBlue = Color(0xFF4D55CC); // Secondary
const Color brightBlue =
    Color.fromARGB(255, 0, 55, 255); // Bright blue for icons

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _totalStockValue = 0.0;
  double _todaySalesTotal = 0.0;

  static const primaryColor = deepIndigo;

  @override
  void initState() {
    super.initState();
    _calculateTotalStockValue();
    _calculateTodaySalesTotal();
  }

  Future<void> _calculateTodaySalesTotal() async {
    final db = DatabaseHelper();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allSales = await db.getAllSales();
    final todaySales = allSales.where(
        (sale) => (sale['date_sold'] ?? '').toString().startsWith(today));
    final total =
        todaySales.fold(0.0, (sum, sale) => sum + (sale['total_price'] ?? 0.0));
    setState(() {
      _todaySalesTotal = total;
    });
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
              (sum, entry) =>
                  sum + (entry['purchase_price'] * entry['quantity']));
    }
    setState(() {
      _totalStockValue = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.1),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                buildHeader(context),
                const SizedBox(height: 20),
                _buildPanelBox(
                  title: 'Quick panel',
                  usePrimaryColor: false,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: [
                        _buildQuickButton(
                            Icons.add_box, 'Add New Product', context),
                        _buildQuickButton(
                            Icons.add_circle_outline, 'Add New Item', context),
                        _buildQuickButton(
                            Icons.point_of_sale, 'Sell Items', context),
                        _buildQuickButton(
                            Icons.inventory_2, 'Inventory', context),
                        _buildQuickButton(
                            Icons.bar_chart, 'Buy & Sell Reports', context),
                        _buildQuickButton(Icons.warning_amber_rounded,
                            'Low Stock Alerts', context),
                        _buildQuickButton(Icons.note_alt, 'Notes', context),
                        _buildQuickButton(Icons.undo, 'Return Item', context),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPanelBox(
                  title: 'Overview',
                  usePrimaryColor: true,
                  stretchFullWidth: true,
                  children: [
                    _buildOverviewTile('৳', 'Total Sales Today',
                        '৳ ${_todaySalesTotal.toStringAsFixed(2)}'),
                    _buildOverviewTile(
                        Icons.shopping_cart, 'Total Purchase Today', '৳ 0.00'),
                    _buildOverviewTile(Icons.inventory, 'Current Stock Value',
                        '৳ ${_totalStockValue.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(context, 0),
    );
  }

  Widget _buildPanelBox(
      {required String title,
      required List<Widget> children,
      required bool usePrimaryColor,
      bool stretchFullWidth = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: stretchFullWidth
          ? const EdgeInsets.symmetric(horizontal: 0)
          : const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: usePrimaryColor ? primaryColor : Colors.white,
        borderRadius: usePrimaryColor
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            : BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: usePrimaryColor ? Colors.white : deepIndigo,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

Widget _buildOverviewTile(dynamic iconOrSymbol, String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          iconOrSymbol is IconData
              ? Icon(iconOrSymbol, size: 22, color: vibrantBlue)
              : Text(iconOrSymbol.toString(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: vibrantBlue)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: vibrantBlue))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: vibrantBlue)),
        ],
      ),
    ),
  );
}

Widget _buildQuickButton(
    IconData iconData, String label, BuildContext context) {
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
      } else if (label == 'Return Item') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ReturnItemPage()));
      }
    },
    child: Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: vibrantBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromARGB(255, 0, 55, 255), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 32, color: deepIndigo),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: deepIndigo),
          ),
        ],
      ),
    ),
  );
}
