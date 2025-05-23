// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'header&nav.dart';
import 'UserSession.dart';
import 'database_helper.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LowStockPageState createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  bool sortAscending = true;
  List<Map<String, dynamic>> lowStockProducts = [];
  List<Map<String, dynamic>> outOfStockProducts = [];
  Map<String, dynamic> stockSummary = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool isLoading = true;
  double _totalStockValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _calculateTotalStockValue();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final allLowStock = await _dbHelper.getLowStockProducts();
      final lowStock =
          allLowStock.where((item) => (item['total_stock'] ?? 0) > 0).toList();
      final outOfStock = await _dbHelper.getOutOfStockProducts();
      final summary = await _dbHelper.getStockSummary();

      setState(() {
        lowStockProducts = List<Map<String, dynamic>>.from(lowStock);
        outOfStockProducts = List<Map<String, dynamic>>.from(outOfStock);
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
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Stock Alert Report');
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
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
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(240, 0, 0, 0)
          : const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isBangla
                                    ? 'স্টকের পরিমাণ অনুসারে সাজান:'
                                    : 'Sort by Stock Level:',
                                style: TextStyle(
                                  color: isDark ? Colors.white : deepIndigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isDark ? Colors.white : deepIndigo,
                                ),
                                onPressed: _sortStock,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionTitle(isBangla
                            ? 'নিম্ন স্টক সতর্কতা'
                            : 'Low Stock Alerts'),
                        _buildLowStockList(),
                        const SizedBox(height: 15),
                        _buildSectionTitle(isBangla
                            ? 'স্টক শেষ সতর্কতা'
                            : 'Out of Stock Alerts'),
                        _buildOutOfStockList(),
                        const SizedBox(height: 15),
                        _buildSectionTitle(
                            isBangla ? 'স্টক রিপোর্ট' : 'Stock Report'),
                        _buildStockReport(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: _exportToPDF,
                              icon: const Icon(Icons.picture_as_pdf,
                                  color: Colors.white),
                              label: Text(
                                isBangla
                                    ? 'স্টক রিপোর্ট এক্সপোর্ট করুন'
                                    : 'Export Stock Alert Report',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? darkShade1 : brightBlue,
                                side: BorderSide(
                                    color: isDark ? darkShade3 : deepIndigo,
                                    width: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNav(context, null),
    );
  }

  Widget _buildLowStockList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (lowStockProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          isBangla
              ? 'নিম্ন স্টক পণ্য পাওয়া যায়নি'
              : 'No low stock products found',
          style: TextStyle(color: isDark ? Colors.white : Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark
              ? darkShade1.withOpacity(0.5)
              : vibrantBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? darkShade3 : brightBlue, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: lowStockProducts.map((product) {
            final productName = product['name'];
            final totalStock = product['total_stock'];
            final reorderLevel = product['low_stock_alert'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isBangla
                          ? '$productName - $totalStock টি বাকি (পুনর্বিন্যাস সীমা $reorderLevel)'
                          : '$productName - $totalStock left (Reorder at $reorderLevel)',
                      style: TextStyle(
                        color: isDark ? Colors.white : deepIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOutOfStockList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    if (outOfStockProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          isBangla
              ? 'স্টক শেষ হওয়া কোনো পণ্য পাওয়া যায়নি'
              : 'No out of stock products found',
          style: TextStyle(color: isDark ? Colors.white : Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark
              ? darkShade1.withOpacity(0.5)
              : vibrantBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? darkShade3 : brightBlue, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: outOfStockProducts.map((product) {
            final productName = product['name'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isBangla
                          ? '$productName - স্টক শেষ'
                          : '$productName - Out of Stock',
                      style: TextStyle(
                        color: isDark ? Colors.white : deepIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.error, color: Colors.red, size: 20),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStockReport() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    TextStyle whiteBold = TextStyle(
      color: isDark ? Colors.white : deepIndigo,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark
              ? darkShade1.withOpacity(0.5)
              : vibrantBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          border: Border.all(color: isDark ? darkShade3 : brightBlue, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla
                  ? 'বর্তমান স্টক মূল্য: ৳${_totalStockValue.toStringAsFixed(2)}'
                  : 'Current Stock Value: ৳${_totalStockValue.toStringAsFixed(2)}',
              style: whiteBold,
            ),
            const SizedBox(height: 8),
            Text(
              isBangla
                  ? 'সর্বাধিক বিক্রিত পণ্য: ${stockSummary['fastest_moving']?.join(', ') ?? 'কোনোটি না'}'
                  : 'Fastest Moving Products: ${stockSummary['fastest_moving']?.join(', ') ?? 'None'}',
              style: whiteBold,
            ),
            const SizedBox(height: 8),
            Text(
              isBangla
                  ? 'স্লো/ডেড স্টক: ${stockSummary['slow_moving']?.join(', ') ?? 'কোনোটি না'}'
                  : 'Slow-Moving or Dead Stock: ${stockSummary['slow_moving']?.join(', ') ?? 'None'}',
              style: whiteBold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : deepIndigo,
        ),
      ),
    );
  }
}
