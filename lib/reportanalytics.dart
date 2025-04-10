import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'UserSession.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'providers/theme_provider.dart';

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
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

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
                                        selectedDateRange = null;
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
                                          : '${selectedDateRange!.start.toLocal()} - ${selectedDateRange!.end.toLocal()}',
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
                          onPressed: () {}, // Implement export logic
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
        unselectedItemColor:
            themeProvider.isDarkMode ? Colors.white70 : Colors.black,
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
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
          children: const [
            ListTile(title: Text('Total Revenue: 100,000 TK')),
            ListTile(title: Text('Total Sales Count: 500')),
            ListTile(
                title: Text('Best-Selling Products: Product A, Product B')),
            ListTile(
                title: Text('Least-Selling Products: Product X, Product Y')),
            Divider(),
            ListTile(title: Text('Gross Profit: 40,000 TK')),
            ListTile(
                title: Text('Total Cost vs Revenue: 60,000 TK vs 100,000 TK')),
            ListTile(
                title: Text(
                    'Profit Margins by Product: Product A - 30%, Product B - 25%')),
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

  Widget _buildBarChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        height: 200,
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
        child: const Center(child: Text('Bar Chart Placeholder')),
      ),
    );
  }
}
