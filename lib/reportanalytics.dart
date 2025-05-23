import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'header&nav.dart';
import 'UserSession.dart';
import 'database_helper.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class ReportAnalyticsPage extends StatefulWidget {
  const ReportAnalyticsPage({super.key});

  @override
  State<ReportAnalyticsPage> createState() => _ReportAnalyticsPageState();
}

class _ReportAnalyticsPageState extends State<ReportAnalyticsPage> {
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
  Map<String, dynamic>? returnAnalytics;

  final Map<String, Map<String, String>> reportTypeLabels = {
    'Daily': {'en': 'Daily', 'bn': 'দৈনিক'},
    'Weekly': {'en': 'Weekly', 'bn': 'সাপ্তাহিক'},
    'Monthly': {'en': 'Monthly', 'bn': 'মাসিক'},
    'Yearly': {'en': 'Yearly', 'bn': 'বার্ষিক'},
    'Custom': {'en': 'Custom', 'bn': 'কাস্টম'},
  };

  final Map<String, Map<String, String>> viewTypeLabels = {
    'Product-wise': {'en': 'Product-wise', 'bn': 'পণ্যভিত্তিক'},
    'Category-wise': {'en': 'Category-wise', 'bn': 'বিভাগভিত্তিক'},
  };

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
        final selectedStart = selectedDateRange?.start ?? now;
        final selectedEnd = selectedDateRange?.end ?? now;

        range = DateTimeRange(
          start: DateTime(
              selectedStart.year, selectedStart.month, selectedStart.day),
          end: DateTime(
              selectedEnd.year, selectedEnd.month, selectedEnd.day, 23, 59, 59),
        );
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

    final updatedAnalytics = await generateSalesAnalytics(
      filtered,
      stockEntries,
      products,
      viewType: selectedViewType,
      selectedProduct: selectedProduct,
      selectedCategory: selectedCategory,
      range: range,
    );

    final productNameMap = {
      for (var p in products)
        p['product_id'].toString(): (p['name'] ?? '').toString()
    };

    final byProductMap = Map<String, Map<String, dynamic>>.from(
      (updatedAnalytics['byProduct'] ?? {}) as Map,
    );

    final returns = await generateReturnAnalytics(
      products,
      byProductMap,
      productNameMap,
      range,
      selectedProduct: selectedProduct,
    );

    setState(() {
      filteredSales = filtered;
      analytics = updatedAnalytics;
      returnAnalytics = returns;
    });
  }

  Future<Map<String, dynamic>> generateSalesAnalytics(
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> stocks,
    List<Map<String, dynamic>> products, {
    required String viewType,
    String? selectedProduct,
    String? selectedCategory,
    DateTimeRange? range,
  }) async {
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

    // Get selectedProductId if filtering by product name
    String? selectedProductId;
    if (selectedProduct != null) {
      selectedProductId = products.firstWhere(
        (p) => (p['name'] ?? '').toLowerCase() == selectedProduct.toLowerCase(),
        orElse: () => {},
      )['product_id'];
    }

    // Collect purchase prices and total purchase cost
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

      if (selectedProductId != null && pid != selectedProductId) continue;

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
      unitPrices.putIfAbsent(pid, () => []).add(sale['unit_price']);

      final existing = byProduct[pid];
      if (existing != null) {
        existing['revenue'] += revenue;
        existing['sales'] += qtySold;
        existing['cost'] += cost;
      } else {
        byProduct[pid] = {
          'revenue': revenue,
          'sales': qtySold,
          'cost': cost,
          'stockRemaining': actualStockQty[pid] ?? 0,
        };
      }

      totalRevenue += revenue;
      totalUnits += qtySold;
      totalCost += cost;
      totalTransactions++;
    }

    //Handle returns (deduct)
    // final allReturns = await DatabaseHelper().getAllReturns();
    // final filteredReturns = allReturns.where((r) {
    //   final date = DateTime.parse(r['date_returned']);
    //   if (range != null) {
    //     return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
    //         date.isBefore(range.end.add(const Duration(days: 1)));
    //   }
    //   return true;
    // }).toList();
    final allReturns = await DatabaseHelper().getAllReturns();
    final filteredReturns = allReturns.where((r) {
      final date = DateTime.parse(r['date_returned']);
      if (range != null) {
        return !date.isBefore(range.start) && !date.isAfter(range.end);
      }
      return true;
    }).toList();

    for (var r in filteredReturns) {
      final pid = r['product_id'];
      if (selectedProductId != null && pid != selectedProductId) continue;

      if (viewType == 'Category-wise' &&
          selectedCategory != null &&
          (productCategoryMap[pid]?.toLowerCase() ?? '') !=
              selectedCategory.toLowerCase()) continue;

      final qty = r['quantity'] ?? 0;
      final sellPrice = r['sell_price'] ?? 0.0;

      double purchasePrice = 0.0;
      if (r['stock_entry_id'] != null) {
        final stockEntry =
            await DatabaseHelper().getStockEntryById(r['stock_entry_id']);
        purchasePrice = stockEntry?['purchase_price'] ?? 0.0;
      } else {
        final product = products.firstWhere((p) => p['product_id'] == pid,
            orElse: () => {});
        purchasePrice = product['purchase_price'] ?? 0.0;
      }

      final returnRevenue = qty * sellPrice;
      final returnCost = qty * purchasePrice;

      totalRevenue -= returnRevenue;
      totalUnits -= qty as int;
      totalCost -= returnCost;

      if (byProduct.containsKey(pid)) {
        byProduct[pid]['revenue'] -= returnRevenue;
        byProduct[pid]['sales'] -= qty;
        byProduct[pid]['cost'] -= returnCost;
      }
    }

    // Finalize profit and margin
    byProduct.forEach((pid, data) {
      final revenue = data['revenue'] ?? 0.0;
      final cost = data['cost'] ?? 0.0;
      final profit = revenue - cost;
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

      data['profit'] = profit;
      data['margin'] = margin;
    });

    result['totalRevenue'] = totalRevenue;
    result['totalSales'] = totalUnits;
    result['cost'] = totalCost;
    result['grossProfit'] = totalRevenue - totalCost;
    result['profitMargin'] = totalRevenue > 0
        ? ((totalRevenue - totalCost) / totalRevenue) * 100
        : 0;
    result['transactionCount'] = totalTransactions;
    result['byProduct'] = byProduct;

    // Price insights
    revenueMap.forEach((pid, _) {
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
          Column(
            children: [
              buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilterControls(),
                      _buildSectionTitle(isBangla
                          ? 'বিক্রয় ও লাভের রিপোর্ট'
                          : 'Sales & Profit Report'),
                      _buildAnalyticsReport(),
                      const SizedBox(height: 10),
                      if (selectedProduct != null) ...[
                        _buildSectionTitle(isBangla
                            ? 'পণ্যের কার্যকারিতা'
                            : 'Product Performance'),
                        _buildProductPerformance(),
                      ],
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? darkShade1 : brightBlue,
                            side: BorderSide(
                                color: isDark ? darkShade3 : deepIndigo,
                                width: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: exportReportAsPDF,
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.white),
                          label: Text(
                            isBangla
                                ? 'রিপোর্ট এক্সপোর্ট করুন (PDF)'
                                : 'Export Report (PDF)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
      bottomNavigationBar: bottomNav(context, 2),
    );
  }

  Widget _buildFilterControls() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    final String allLabel = isBangla ? 'সব' : 'All';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        children: [
          _buildStyledDropdown(
            selectedReportType,
            reportTypes,
            (value) {
              setState(() {
                selectedReportType = value!;
                applyFilters();
              });
            },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? darkShade1 : Colors.white,
                side: BorderSide(color: isDark ? darkShade3 : deepIndigo),
                elevation: 1,
              ),
              child: Text(
                selectedDateRange == null
                    ? (isBangla ? 'তারিখ নির্বাচন করুন' : 'Select Date Range')
                    : '${DateFormat.yMd().format(selectedDateRange!.start)} - ${DateFormat.yMd().format(selectedDateRange!.end)}',
                style: TextStyle(color: isDark ? Colors.white : deepIndigo),
              ),
            ),
          _buildStyledDropdown(
            selectedViewType,
            viewTypes,
            (value) {
              setState(() {
                selectedViewType = value!;
                selectedProduct = null;
                selectedCategory = null;
                applyFilters();
              });
            },
          ),
          if (selectedViewType == 'Product-wise')
            _buildStyledDropdown(
              selectedProduct ?? allLabel,
              [allLabel, ...allProducts],
              (value) {
                setState(() {
                  selectedProduct =
                      (value == 'All' || value == 'সব') ? null : value;
                  applyFilters();
                });
              },
            )
          else if (selectedViewType == 'Category-wise')
            _buildStyledDropdown(
              selectedCategory ?? allLabel,
              [allLabel, ...allCategories],
              (value) {
                setState(() {
                  selectedCategory =
                      (value == 'All' || value == 'সব') ? null : value;
                  applyFilters();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown(
      String currentValue, List<String> options, Function(String?) onChanged) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? darkShade1 : Colors.white,
        border: Border.all(color: isDark ? Colors.white : deepIndigo),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: currentValue,
        underline: const SizedBox(),
        iconEnabledColor: isDark ? darkShade3 : deepIndigo,
        dropdownColor: isDark ? darkShade1 : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : deepIndigo),
        onChanged: onChanged,
        items: options.map((type) {
          String label = type;
          if (reportTypeLabels.containsKey(type)) {
            label = isBangla
                ? reportTypeLabels[type]!['bn']!
                : reportTypeLabels[type]!['en']!;
          } else if (viewTypeLabels.containsKey(type)) {
            label = isBangla
                ? viewTypeLabels[type]!['bn']!
                : viewTypeLabels[type]!['en']!;
          }
          return DropdownMenuItem(
            value: type,
            child: Text(label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalyticsReport() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    final byProduct = analytics['byProduct'] as Map<String, dynamic>? ?? {};
    final priceInsights =
        analytics['priceInsights'] as Map<String, dynamic>? ?? {};
    final selected = selectedProduct != null;

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
                  ? 'মোট রাজস্ব: ৳${analytics['totalRevenue']?.toStringAsFixed(2)}'
                  : 'Total Revenue: ৳${analytics['totalRevenue']?.toStringAsFixed(2)}',
              style: whiteBold,
            ),
            Text(
              isBangla
                  ? 'মোট বিক্রয়: ${analytics['totalSales']} ইউনিট'
                  : 'Total Sales: ${analytics['totalSales']} units',
              style: whiteBold,
            ),
            Text(
              isBangla
                  ? 'পণ্য খরচ (COGS): ৳${analytics['cost']?.toStringAsFixed(2)}'
                  : 'COGS (Cost of Goods Sold): ৳${analytics['cost']?.toStringAsFixed(2)}',
              style: whiteBold,
            ),
            if (!selected && analytics['bestSeller'] != '')
              Text(
                isBangla
                    ? 'সর্বাধিক বিক্রিত পণ্য: ${analytics['bestSeller']}'
                    : 'Best Selling Product: ${analytics['bestSeller']}',
                style: whiteBold,
              ),
            if (!selected && analytics['leastSeller'] != '')
              Text(
                isBangla
                    ? 'সর্বনিম্ন বিক্রিত পণ্য: ${analytics['leastSeller']}'
                    : 'Least Selling Product: ${analytics['leastSeller']}',
                style: whiteBold,
              ),
            if (!selected && analytics['bestMarginProduct'] != null)
              Text(
                isBangla
                    ? 'সর্বোচ্চ লাভের মার্জিন: ${analytics['bestMarginProduct']} '
                        '(${analytics['bestMarginValue']?.toStringAsFixed(2)}%)'
                    : 'Best Profit Margin: ${analytics['bestMarginProduct']} '
                        '(${analytics['bestMarginValue']?.toStringAsFixed(2)}%)',
                style: whiteBold,
              ),
            Divider(color: isDark ? darkShade3 : deepIndigo),
            Text(
              isBangla
                  ? 'মোট লাভ: ৳${analytics['grossProfit']?.toStringAsFixed(2)}'
                  : 'Gross Profit: ৳${analytics['grossProfit']?.toStringAsFixed(2)}',
              style: whiteBold,
            ),
            Text(
              isBangla
                  ? 'লাভের হার: ${analytics['profitMargin']?.toStringAsFixed(2)} %'
                  : 'Profit Margin: ${analytics['profitMargin']?.toStringAsFixed(2)} %',
              style: whiteBold,
            ),
            if (selected && byProduct.isNotEmpty)
              Builder(builder: (_) {
                final pid = byProduct.keys.first;
                final insight = priceInsights[pid];
                if (insight != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: isDark ? darkShade3 : deepIndigo),
                      Text(
                        isBangla
                            ? 'গড় বিক্রয়মূল্য: ৳${(insight['avgSell'] as double).toStringAsFixed(2)}'
                            : 'Avg Selling Price: ৳${(insight['avgSell'] as double).toStringAsFixed(2)}',
                        style: whiteBold,
                      ),
                      Text(
                        isBangla
                            ? 'গড় ক্রয়মূল্য: ৳${(insight['avgPurchase'] as double).toStringAsFixed(2)}'
                            : 'Avg Purchase Price: ৳${(insight['avgPurchase'] as double).toStringAsFixed(2)}',
                        style: whiteBold,
                      ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    final byProduct = analytics['byProduct'] as Map<String, dynamic>;
    final selected = selectedProduct != null;

    TextStyle whiteBold = TextStyle(
      color: isDark ? Colors.white : deepIndigo,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    if (!selected || byProduct.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            color: isDark ? darkShade1.withOpacity(0.5) : Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                isBangla
                    ? 'নির্বাচিত পণ্যের জন্য কোনো কার্যকারিতা তথ্য পাওয়া যায়নি।'
                    : 'No performance data available for the selected product.',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey, fontSize: 14),
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
            color: isDark
                ? darkShade1.withOpacity(0.5)
                : vibrantBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            border:
                Border.all(color: isDark ? darkShade3 : brightBlue, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                isBangla
                    ? '  বিক্রিত ইউনিট: ${data['sales']}'
                    : '  Units Sold: ${data['sales']}',
                style: whiteBold,
              ),
              Text(
                isBangla
                    ? '  আয়: ৳${(data['revenue'] as double).toStringAsFixed(2)}'
                    : '  Revenue: ৳${(data['revenue'] as double).toStringAsFixed(2)}',
                style: whiteBold,
              ),
              Text(
                isBangla
                    ? '  লাভ: ৳${(data['profit'] as double).toStringAsFixed(2)}'
                    : '  Profit: ৳${(data['profit'] as double).toStringAsFixed(2)}',
                style: whiteBold,
              ),
              Text(
                isBangla
                    ? '  অবশিষ্ট স্টক: ${data['stockRemaining']}'
                    : '  Stock Remaining: ${data['stockRemaining']}',
                style: whiteBold,
              ),
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

  Future<Map<String, dynamic>> generateReturnAnalytics(
    List<Map<String, dynamic>> products,
    Map<String, Map<String, dynamic>> byProduct,
    Map<String, String> productNameMap,
    DateTimeRange range, {
    String? selectedProduct,
  }) async {
    final returnsData = (await DatabaseHelper().getAllReturns()).where((r) {
      final date = DateTime.parse(r['date_returned']);
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();

    final returnMap = <String, int>{};
    final returnValueMap = <String, double>{};
    final profitLossMap = <String, double>{};
    int totalReturns = 0;
    double totalReturnValue = 0.0;
    double totalProfitLoss = 0.0;
    double totalReturnSellValue = 0.0;

    for (var returnItem in returnsData) {
      final pid = returnItem['product_id'];
      final productName = productNameMap[pid]?.toLowerCase() ?? '';

      //Skip if selectedProduct is set and doesn't match
      if (selectedProduct != null &&
          productName != selectedProduct.toLowerCase()) {
        continue;
      }

      final qty = returnItem['quantity'] as int;
      final sellPrice = returnItem['sell_price'] as double;
      final returnSellValue = qty * sellPrice;
      totalReturnSellValue += returnSellValue;

      // Use stock_entry_id to find the actual purchase price
      double purchasePrice = 0.0;

      if (returnItem['stock_entry_id'] != null) {
        final stockEntryId = returnItem['stock_entry_id'];
        final stockEntry =
            await DatabaseHelper().getStockEntryById(stockEntryId);
        purchasePrice = stockEntry?['purchase_price'] ?? 0.0;
      } else {
        final product = products.firstWhere((p) => p['product_id'] == pid);
        purchasePrice = product['purchase_price'] as double;
      }

      final returnValue = qty * purchasePrice;
      final profitLoss = qty * (sellPrice - purchasePrice);

      returnMap[pid] = (returnMap[pid] ?? 0) + qty;
      returnValueMap[pid] = (returnValueMap[pid] ?? 0.0) + returnValue;
      profitLossMap[pid] = (profitLossMap[pid] ?? 0.0) + profitLoss;

      totalReturns += qty;
      totalReturnValue += returnValue;
      totalProfitLoss += profitLoss;

      if (byProduct.containsKey(pid)) {
        byProduct[pid]!['returns'] = returnMap[pid];
        byProduct[pid]!['returnValue'] = returnValueMap[pid];
        byProduct[pid]!['returnProfitLoss'] = profitLossMap[pid];
      }
    }

    return {
      'totalReturns': totalReturns,
      'totalReturnValue': totalReturnValue,
      'totalReturnSellValue': totalReturnSellValue,
      'totalProfitLoss': totalProfitLoss,
      'byProduct': returnMap,
      'mostReturned': returnMap.isNotEmpty
          ? productNameMap[returnMap.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key] ??
              ''
          : ''
    };
  }

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
            pw.Text('Powered by GudamGuru',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
