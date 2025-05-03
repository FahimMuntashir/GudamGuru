import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'UserSession.dart';
import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'reportanalytics.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  _LowStockPageState createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  bool sortAscending = true;
  List<Map<String, dynamic>> lowStockProducts = [];
  List<Map<String, dynamic>> outOfStockProducts = [];
  Map<String, dynamic> stockSummary = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final lowStock = await _dbHelper.getLowStockProducts();
      final outOfStock = await _dbHelper.getOutOfStockProducts();
      final summary = await _dbHelper.getStockSummary();

      setState(() {
        lowStockProducts = lowStock;
        outOfStockProducts = outOfStock;
        stockSummary = summary;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  void _sortStock() {
    setState(() {
      if (sortAscending) {
        lowStockProducts.sort(
            (a, b) => (a['total_stock'] ?? 0).compareTo(b['total_stock'] ?? 0));
      } else {
        lowStockProducts.sort(
            (a, b) => (b['total_stock'] ?? 0).compareTo(a['total_stock'] ?? 0));
      }
      sortAscending = !sortAscending;
    });
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      // Add company header
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${UserSession().companyName} - Stock Alert Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // Low Stock Products
              pw.Text('Low Stock Products',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Product Name')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Current Stock')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Alert Level')),
                    ],
                  ),
                  ...lowStockProducts.map((product) => pw.TableRow(
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(product['name'])),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${product['total_stock']}')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${product['low_stock_alert']}')),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 20),

              // Out of Stock Products
              pw.Text('Out of Stock Products',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Product Name')),
                    ],
                  ),
                  ...outOfStockProducts.map((product) => pw.TableRow(
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(product['name'])),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 20),

              // Stock Summary
              pw.Text('Stock Summary',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Stock Value: ${stockSummary['total_value']} TK'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Fastest Moving Products: ${stockSummary['fastest_moving'].join(', ')}'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Slow Moving Products: ${stockSummary['slow_moving'].join(', ')}'),
            ],
          ),
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/stock_alert_report.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles([XFile(file.path)], text: 'Stock Alert Report');
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
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
                            Image.asset('assets/images/logo.png', width: 150),
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

                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
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
                            onPressed: _exportToPDF,
                            child: const Text(
                                'Export Stock Alert Report (📤 PDF)'),
                          ),
                        ),
                      ],
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
    if (lowStockProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No low stock products found'),
      );
    }

    return Column(
      children: lowStockProducts.map((product) {
        return ListTile(
          title: Text('${product['name']} - ${product['total_stock']} left'),
          subtitle: Text('Reorder at ${product['low_stock_alert']}'),
          trailing: const Icon(Icons.warning, color: Colors.orange),
        );
      }).toList(),
    );
  }

  Widget _buildOutOfStockList() {
    if (outOfStockProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No out of stock products found'),
      );
    }

    return Column(
      children: outOfStockProducts.map((product) {
        return ListTile(
          title: Text('${product['name']} - Out of Stock'),
          trailing: const Icon(Icons.error, color: Colors.red),
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
          children: [
            ListTile(
              title: Text(
                  'Current Stock Value: ${stockSummary['total_value']?.toStringAsFixed(2) ?? '0.00'} TK'),
            ),
            ListTile(
              title: Text(
                  'Fastest Moving Products: ${stockSummary['fastest_moving']?.join(', ') ?? 'None'}'),
            ),
            ListTile(
              title: Text(
                  'Slow-Moving or Dead Stock: ${stockSummary['slow_moving']?.join(', ') ?? 'None'}'),
            ),
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
