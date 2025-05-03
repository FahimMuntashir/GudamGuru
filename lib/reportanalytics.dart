import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'UserSession.dart';
import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'providers/theme_provider.dart';

class ReportAnalyticsPage extends StatefulWidget {
  const ReportAnalyticsPage({super.key});

  @override
  State<ReportAnalyticsPage> createState() => _ReportAnalyticsPageState();
}

class _ReportAnalyticsPageState extends State<ReportAnalyticsPage> {
  int _selectedIndex = 2;
  String selectedReportType = 'Daily';
  String selectedViewType = 'Product-wise';
  String? selectedProduct;
  String? selectedCategory;
  DateTimeRange? selectedDateRange;

  List<String> reportTypes = ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom'];
  List<String> viewTypes = ['Product-wise', 'Category-wise'];
  List<Map<String, dynamic>> allSales = [];
  List<Map<String, dynamic>> filteredSales = [];
  List<Map<String, dynamic>> stockEntries = [];
  List<String> allProducts = [];
  List<String> allCategories = [];

  Map<String, dynamic> analytics = {
    'totalRevenue': 0.0,
    'totalSales': 0,
    'grossProfit': 0.0,
    'cost': 0.0,
    'profitMargin': 0.0,
    'transactionCount': 0,
    'byProduct': <String, dynamic>{},
    'bestSeller': '',
    'leastSeller': '',
    'priceInsights': <String, dynamic>{},
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db = DatabaseHelper();

    List<Map<String, dynamic>> sales = await db.getAllSales();
    List<Map<String, dynamic>> stocks = [];
    List<Map<String, dynamic>> products = await db.getAllProducts();

    for (var p in products) {
      stocks += await db.getStockEntriesForProduct(p['product_id']);
    }

    setState(() {
      allSales = sales;
      stockEntries = stocks;
      allProducts = products.map((p) => p['name'] as String).toList();
      allCategories =
          products.map((p) => p['category'] as String).toSet().toList();
    });

    applyFilters();
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

  void applyFilters() async {
    DateTime now = DateTime.now();
    DateTimeRange range;

    switch (selectedReportType) {
      case 'Daily':
        range = DateTimeRange(
            start: DateTime(now.year, now.month, now.day), end: now);
        break;
      case 'Weekly':
        range = DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
        break;
      case 'Monthly':
        range =
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
        break;
      case 'Yearly':
        range = DateTimeRange(start: DateTime(now.year), end: now);
        break;
      case 'Custom':
        range = selectedDateRange ?? DateTimeRange(start: now, end: now);
        break;
      default:
        range = DateTimeRange(start: now, end: now);
    }

    List<Map<String, dynamic>> filtered = allSales.where((sale) {
      DateTime date = DateTime.parse(sale['date_sold']);
      return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();

    final products = await DatabaseHelper().getAllProducts();

    setState(() {
      filteredSales = filtered;
      analytics = generateSalesAnalytics(
        filtered,
        stockEntries,
        products,
        viewType: selectedViewType,
        selectedProduct: selectedProduct,
        selectedCategory: selectedCategory,
      );
    });
  }

  Map<String, dynamic> generateSalesAnalytics(
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> stocks,
    List<Map<String, dynamic>> products, {
    required String viewType,
    String? selectedProduct,
    String? selectedCategory,
  }) {
    final result = {
      'totalRevenue': 0.0,
      'totalSales': 0,
      'grossProfit': 0.0,
      'cost': 0.0,
      'totalPurchaseCost': 0.0,
      'profitMargin': 0.0,
      'transactionCount': 0,
      'byProduct': <String, dynamic>{},
      'bestSeller': '',
      'leastSeller': '',
      'priceInsights': <String, Map<String, dynamic>>{},
    };

    final Map<String, double> revenueMap = {};
    final Map<String, int> salesQtyMap = {};
    final Map<String, int> transactionCountMap = {};
    final Map<String, List<double>> unitPrices = {};
    final Map<String, List<double>> purchasePrices = {};
    final Map<String, int> actualStockQty = {
      for (var p in products) p['product_id']: p['quantity'] ?? 0
    };
    final Map<String, String> productNameMap = {
      for (var p in products) p['product_id']: p['name'] ?? ''
    };
    final Map<String, String> productCategoryMap = {
      for (var p in products) p['product_id']: p['category'] ?? ''
    };

    // Collect all known purchase prices from stock (for price insights only)
    for (var entry in stocks) {
      final pid = entry['product_id'];
      purchasePrices.putIfAbsent(pid, () => []).add(entry['purchase_price']);
      result['totalPurchaseCost'] =
          (result['totalPurchaseCost'] as double? ?? 0.0) +
              ((entry['purchase_price'] ?? 0.0) as double) *
                  ((entry['quantity'] ?? 0) as int);
    }

    double totalRevenue = 0.0;
    int totalUnits = 0;
    double totalCost = 0.0;
    int totalTransactions = 0;

    final byProduct = <String, dynamic>{};
    final priceInsights = <String, Map<String, dynamic>>{};

    for (var sale in sales) {
      final pid = sale['product_id'];
      final name = sale['name'];

      // Filter by selected product (product-wise)
      if (selectedProduct != null &&
          name.toLowerCase() != selectedProduct.toLowerCase()) continue;

      // Filter by selected category (category-wise)
      if (viewType == 'Category-wise' &&
          selectedCategory != null &&
          (productCategoryMap[pid]?.toLowerCase() ?? '') !=
              selectedCategory.toLowerCase()) continue;

      final qtySold = sale['quantity'] as int;
      final revenue = sale['total_price'] as double;
      final purchasePrice = (sale['purchase_price'] ?? 0.0) as double;

      final cost = qtySold * purchasePrice;

      revenueMap[pid] = (revenueMap[pid] ?? 0) + revenue;
      salesQtyMap[pid] = (salesQtyMap[pid] ?? 0) + qtySold;
      transactionCountMap[pid] = (transactionCountMap[pid] ?? 0) + 1;
      unitPrices.putIfAbsent(pid, () => []).add(sale['unit_price']);

      final existing = byProduct[pid];
      if (existing != null) {
        existing['revenue'] += revenue;
        existing['sales'] += qtySold;
        existing['cost'] += cost;
        existing['profit'] = existing['revenue'] - existing['cost'];
        existing['margin'] = existing['revenue'] > 0
            ? (existing['profit'] / existing['revenue']) * 100
            : 0;
      } else {
        byProduct[pid] = {
          'revenue': revenue,
          'sales': qtySold,
          'cost': cost,
          'profit': revenue - cost,
          'margin': revenue > 0 ? ((revenue - cost) / revenue) * 100 : 0,
          'stockRemaining': actualStockQty[pid] ?? 0,
        };
      }

      totalRevenue += revenue;
      totalUnits += qtySold;
      totalCost += cost;
      totalTransactions++;
    }

    result['totalRevenue'] = totalRevenue;
    result['totalSales'] = totalUnits;
    result['cost'] = totalCost;
    result['grossProfit'] = totalRevenue - totalCost;
    result['profitMargin'] = totalRevenue > 0
        ? ((totalRevenue - totalCost) / totalRevenue) * 100
        : 0.0;
    result['transactionCount'] = totalTransactions;
    result['byProduct'] = byProduct;

    // For price insight charts
    revenueMap.forEach((pid, revenue) {
      priceInsights[pid] = {
        'avgSell': unitPrices[pid]!.isNotEmpty
            ? unitPrices[pid]!.reduce((a, b) => a + b) / unitPrices[pid]!.length
            : 0.0,
        'avgPurchase': purchasePrices[pid]!.isNotEmpty
            ? purchasePrices[pid]!.reduce((a, b) => a + b) /
                purchasePrices[pid]!.length
            : 0.0,
      };
    });

    result['priceInsights'] = priceInsights;

    if (selectedProduct == null && byProduct.isNotEmpty) {
      final sorted = byProduct.entries.toList()
        ..sort((a, b) => b.value['sales'].compareTo(a.value['sales']));
      result['bestSeller'] =
          productNameMap[sorted.first.key] ?? sorted.first.key;
      result['leastSeller'] =
          productNameMap[sorted.last.key] ?? sorted.last.key;

      final sortedByMargin = byProduct.entries
          .where((e) => e.value['margin'] != null)
          .toList()
        ..sort((a, b) => (b.value['margin'] as double)
            .compareTo(a.value['margin'] as double));

      if (sortedByMargin.isNotEmpty) {
        result['bestMarginProduct'] =
            productNameMap[sortedByMargin.first.key] ??
                sortedByMargin.first.key;
        result['bestMarginValue'] =
            sortedByMargin.first.value['margin']?.toDouble() ?? 0.0;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilterControls(),
                      _buildSectionTitle('Sales & Profit Report'),
                      _buildAnalyticsReport(),
                      if (selectedProduct != null) ...[
                        _buildSectionTitle('Product Performance'),
                        _buildProductPerformance(),
                      ],

                      // _buildBarChartSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton.icon(
                          onPressed: exportReportAsPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export Report (PDF)'),
                        ),
                      )
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor:
            themeProvider.isDarkMode ? Colors.white70 : Colors.black,
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          }
          if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const InventoryPage()));
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/logo.png', width: 150),
          Text(UserSession().companyName ?? '',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          DropdownButton<String>(
            value: selectedReportType,
            onChanged: (value) => setState(() {
              selectedReportType = value!;
              applyFilters();
            }),
            items: reportTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
          ),
          if (selectedReportType == 'Custom')
            ElevatedButton(
              onPressed: () async {
                DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDateRange = picked;
                    applyFilters();
                  });
                }
              },
              child: Text(selectedDateRange == null
                  ? 'Select Date Range'
                  : '${DateFormat.yMd().format(selectedDateRange!.start)} - ${DateFormat.yMd().format(selectedDateRange!.end)}'),
            ),
          DropdownButton<String>(
            value: selectedViewType,
            onChanged: (value) {
              setState(() {
                selectedViewType = value!;
                selectedProduct = null;
                selectedCategory = null;
                applyFilters();
              });
            },
            items: viewTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
          ),
          if (selectedViewType == 'Product-wise')
            DropdownButton<String>(
              value: selectedProduct ?? 'All',
              onChanged: (value) {
                setState(() {
                  selectedProduct = (value == 'All') ? null : value;
                  applyFilters();
                });
              },
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All')),
                ...allProducts
                    .map((p) => DropdownMenuItem(value: p, child: Text(p))),
              ],
            )
          else if (selectedViewType == 'Category-wise')
            DropdownButton<String>(
              value: selectedCategory ?? 'All',
              onChanged: (value) {
                setState(() {
                  selectedCategory = (value == 'All') ? null : value;
                  applyFilters();
                });
              },
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All')),
                ...allCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildAnalyticsReport() {
    final byProduct = analytics['byProduct'] as Map<String, dynamic>? ?? {};
    final priceInsights =
        analytics['priceInsights'] as Map<String, dynamic>? ?? {};
    final selected = selectedProduct != null;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Total Revenue: ৳${analytics['totalRevenue']?.toStringAsFixed(2)}'),
            Text('Total Sales: ${analytics['totalSales']} units'),
            // Text(
            //     'Total Purchase Cost: ৳${analytics['totalPurchaseCost']?.toStringAsFixed(2)}'),
            Text(
                'COGS (Cost of Goods Sold): ৳${analytics['cost']?.toStringAsFixed(2)}'),
            Text('Number of Transactions: ${analytics['transactionCount']}'),
            if (!selected && analytics['bestSeller'] != '')
              Text('Best Selling Product: ${analytics['bestSeller']}'),
            if (!selected && analytics['leastSeller'] != '')
              Text('Least Selling Product: ${analytics['leastSeller']}'),
            if (!selected && analytics['bestMarginProduct'] != null)
              Text(
                'Best Profit Margin: ${analytics['bestMarginProduct']} '
                '(${analytics['bestMarginValue']?.toStringAsFixed(2)}%)',
              ),
            const Divider(),
            Text(
                'Gross Profit: ৳${analytics['grossProfit']?.toStringAsFixed(2)}'),
            Text(
                'Profit Margin: ${analytics['profitMargin']?.toStringAsFixed(2)} %'),
            if (selected && byProduct.isNotEmpty)
              Builder(builder: (_) {
                final pid = byProduct.keys.first;
                final insight = priceInsights[pid];
                if (insight != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text(
                          'Avg Selling Price: ৳${(insight['avgSell'] as double).toStringAsFixed(2)}'),
                      Text(
                          'Avg Purchase Price: ৳${(insight['avgPurchase'] as double).toStringAsFixed(2)}'),
                    ],
                  );
                }
                return const SizedBox();
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPerformance() {
    final byProduct = analytics['byProduct'] as Map<String, dynamic>;
    final selected = selectedProduct != null;

    if (!selected || byProduct.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            color: Colors.white,
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'No performance data available for the selected product.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    final entry = byProduct.entries.first;
    final data = entry.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(' $selectedProduct'),
              Text('  Units Sold: ${data['sales']}'),
              Text(
                  '  Revenue: ৳${(data['revenue'] as double).toStringAsFixed(2)}'),
              Text(
                  '  Profit: ৳${(data['profit'] as double).toStringAsFixed(2)}'),
              Text('  Stock Remaining: ${data['stockRemaining']}'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildBarChartSection() {
  //   final byProduct = analytics['byProduct'] as Map<String, dynamic>;
  //   final List<BarChartGroupData> barGroups = [];

  //   int index = 0;
  //   byProduct.forEach((key, value) {
  //     barGroups.add(
  //       BarChartGroupData(x: index++, barRods: [
  //         BarChartRodData(toY: value['revenue'], width: 6),
  //         BarChartRodData(toY: value['cost'], width: 6),
  //         BarChartRodData(toY: value['profit'], width: 6),
  //       ]),
  //     );
  //   });

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //     child: Container(
  //       height: 300,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
  //       ),
  //       child: BarChart(
  //         BarChartData(
  //           barGroups: barGroups,
  //           titlesData: FlTitlesData(
  //             leftTitles: AxisTitles(
  //               sideTitles: SideTitles(showTitles: true, reservedSize: 40),
  //             ),
  //             bottomTitles: AxisTitles(
  //               sideTitles: SideTitles(
  //                 showTitles: true,
  //                 getTitlesWidget: (value, meta) {
  //                   return Text(byProduct.keys.elementAt(value.toInt()));
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> exportReportAsPDF() async {
    final pdf = pw.Document();
    final company = UserSession().companyName ?? 'Company';

    final byProduct = analytics['byProduct'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$company Report',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text('Total Revenue: ৳${analytics['totalRevenue']}'),
            pw.Text('Total Sales: ${analytics['totalSales']} units'),
            if (selectedProduct == null && analytics['bestSeller'] != '')
              pw.Text('Best-Selling Product: ${analytics['bestSeller']}'),
            if (selectedProduct == null && analytics['leastSeller'] != '')
              pw.Text('Least-Selling Product: ${analytics['leastSeller']}'),
            pw.Text('Gross Profit: ৳${analytics['grossProfit']}'),
            pw.Text(
                'Cost vs Revenue: ৳${analytics['cost']} vs ৳${analytics['totalRevenue']}'),
            if (selectedProduct != null && byProduct.isNotEmpty)
              pw.Text(
                  'Profit Margin: ${byProduct.entries.first.value['margin'].toStringAsFixed(2)}%'),
            pw.Spacer(),
            pw.Text('Powered by GudamGuru', style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
