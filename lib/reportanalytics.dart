import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gudam_guru/profile_page.dart';
import 'package:provider/provider.dart';

import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'providers/product_provider.dart';
import 'providers/user_provider.dart';

class ReportAnalyticsPage extends StatefulWidget {
  const ReportAnalyticsPage({super.key});

  @override
  _ReportAnalyticsPageState createState() => _ReportAnalyticsPageState();
}

class _ReportAnalyticsPageState extends State<ReportAnalyticsPage> {
  int _selectedIndex = 2;
  String selectedReportType = 'Daily';
  final List<String> reportTypes = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
    'Custom'
  ];
  final List<String> categoryTypes = ['Category-wise', 'Product-wise', 'All'];
  String selectedCategory = 'All';
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Set default date range to today
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final productProvider = context.watch<ProductProvider>();

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

                      // Filters & Time Range Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DropdownButton<String>(
                                  value: selectedReportType,
                                  items: reportTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedReportType = newValue!;
                                      if (selectedReportType == 'Yearly') {
                                        selectedDateRange = DateTimeRange(
                                          start: DateTime(
                                              DateTime.now().year, 1, 1),
                                          end: DateTime(
                                              DateTime.now().year, 12, 31),
                                        );
                                      } else if (selectedReportType !=
                                          'Custom') {
                                        final now = DateTime.now();
                                        switch (selectedReportType) {
                                          case 'Daily':
                                            selectedDateRange = DateTimeRange(
                                              start: DateTime(
                                                  now.year, now.month, now.day),
                                              end: DateTime(
                                                  now.year, now.month, now.day),
                                            );
                                            break;
                                          case 'Weekly':
                                            selectedDateRange = DateTimeRange(
                                              start: now.subtract(
                                                  const Duration(days: 7)),
                                              end: now,
                                            );
                                            break;
                                          case 'Monthly':
                                            selectedDateRange = DateTimeRange(
                                              start: DateTime(
                                                  now.year, now.month, 1),
                                              end: DateTime(
                                                  now.year, now.month + 1, 0),
                                            );
                                            break;
                                        }
                                      }
                                    });
                                  },
                                ),
                                if (selectedReportType == 'Custom')
                                  ElevatedButton(
                                    onPressed: () async {
                                      DateTimeRange? picked =
                                          await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedDateRange = picked;
                                        });
                                      }
                                    },
                                    child: Text(
                                      selectedDateRange == null
                                          ? 'Select Date Range'
                                          : '${selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              value: selectedCategory,
                              items: categoryTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sales Performance & Profit Report in One Container
                      _buildSectionTitle('Sales & Profit Report'),
                      _buildSalesAndProfitReport(),
                      _buildBarChart(),

                      // Export Report Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement export functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Export functionality coming soon'),
                              ),
                            );
                          },
                          child: const Text('Export Report (PDF/CSV) 📤'),
                        ),
                      ),
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
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

  Widget _buildSalesAndProfitReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ProductProvider>().getSalesByDateRange(
            selectedDateRange!.start,
            selectedDateRange!.end,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final salesData = snapshot.data ?? [];
        double totalRevenue = 0.0;
        int totalSalesCount = 0;

        for (var sale in salesData) {
          totalRevenue += (sale['total_sales'] ?? 0).toDouble();
          totalSalesCount += ((sale['transaction_count'] ?? 0) as num).toInt();
        }

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
                      'Total Revenue: ৳${totalRevenue.toStringAsFixed(2)}'),
                ),
                ListTile(
                  title: Text('Total Sales Count: $totalSalesCount'),
                ),
                const Divider(),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<ProductProvider>().getTopProducts(5),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final topProducts = snapshot.data ?? [];
                    return Column(
                      children: [
                        const ListTile(
                          title: Text('Top Selling Products:'),
                        ),
                        ...topProducts.map((product) => ListTile(
                              title: Text(product['name']),
                              subtitle: Text(
                                'Sales: ${product['transaction_count']} | Revenue: ৳${product['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ProductProvider>().getSalesByDateRange(
            selectedDateRange!.start,
            selectedDateRange!.end,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final salesData = snapshot.data ?? [];
        if (salesData.isEmpty) {
          return const Center(
            child: Text('No sales data available for the selected period'),
          );
        }

        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: salesData.fold<double>(
                0,
                (max, sale) => (sale['total_sales'] ?? 0) > max
                    ? (sale['total_sales'] ?? 0)
                    : max,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.parse(salesData[value.toInt()]['sale_date']);
                      return Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '৳${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              barGroups: salesData.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['total_sales'] ?? 0).toDouble(),
                      color: Colors.green,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
