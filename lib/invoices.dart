import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'reportanalytics.dart';
import 'profile.dart';
import 'UserSession.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  DateTime? selectedDate;

  double _calculateTotalSales() {
    return filteredInvoices.fold(
      0.0,
      (sum, inv) => sum + (inv['total_price'] ?? 0.0),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final db = DatabaseHelper();
    final allSales = await db.getAllSales();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var sale in allSales) {
      final invoiceNo = sale['invoice_number'] ?? 'Unknown';
      if (!grouped.containsKey(invoiceNo)) {
        grouped[invoiceNo] = [];
      }
      grouped[invoiceNo]!.add(sale);
    }

    final result = grouped.entries.map((entry) {
      double total =
          entry.value.fold(0.0, (sum, e) => sum + (e['total_price'] as double));
      return {
        'invoice_number': entry.key,
        'date_sold': entry.value.first['date_sold'],
        'time_sold': entry.value.first['time_sold'],
        'total_price': total,
        'items': entry.value,
      };
    }).toList();

    setState(() {
      invoices = result;
      _applyDateFilter();
    });
  }

  // void _applyDateFilter() {
  //   if (selectedDate == null) {
  //     filteredInvoices = invoices;
  //   } else {
  //     final formatted = DateFormat('yyyy-MM-dd').format(selectedDate!);
  //     filteredInvoices = invoices
  //         .where((inv) => inv['date_sold'].startsWith(formatted))
  //         .toList();
  //   }
  // }
  void _applyDateFilter() {
    List<Map<String, dynamic>> temp = invoices;

    if (selectedDate != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(selectedDate!);
      temp =
          temp.where((inv) => inv['date_sold'].startsWith(formatted)).toList();
    }

    String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      temp = temp.where((invoice) {
        return invoice['items'].any((item) {
          final pid = item['product_id'].toString().toLowerCase();
          final name = (item['name'] ?? '').toString().toLowerCase();
          return pid.contains(query) || name.contains(query);
        });
      }).toList();
    }

    setState(() {
      filteredInvoices = temp;
    });
  }

  Future<void> _exportInvoiceAsPdf(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();
    final companyName = UserSession().companyName ?? 'Company';

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(companyName,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text(
                  '${DateFormat('dd-MM-yyyy').format(DateTime.parse(invoice['date_sold']))} '
                  '${DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(invoice['time_sold']))}',
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Invoice #: ${invoice['invoice_number']}'),
            pw.SizedBox(height: 10),
            pw.Text('Details:'),
            ...invoice['items']
                .map<pw.Widget>((item) => pw.Text(
                    '${item['product_id']} - ${item['name']}   :::   Quantity: ${item['quantity']} x TK ${item['unit_price']} = TK ${item['total_price']}'))
                .toList(),
            pw.Divider(),
            pw.Text('Total: TK ${invoice['total_price'].toStringAsFixed(2)}'),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text('Powered by GudamGuru',
                  style: pw.TextStyle(fontSize: 10)),
            )
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportAllInvoices() async {
    final pdf = pw.Document();
    final companyName = UserSession().companyName ?? 'Company';

    for (var invoice in filteredInvoices) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(companyName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(
                    '${DateFormat('dd-MM-yyyy').format(DateTime.parse(invoice['date_sold']))} '
                    '${DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(invoice['time_sold']))}',
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Invoice #: ${invoice['invoice_number']}'),
              pw.SizedBox(height: 10),
              pw.Text('Details:'),
              ...invoice['items']
                  .map<pw.Widget>((item) => pw.Text(
                      '${item['product_id']} - ${item['name']}   :::   Quantity: ${item['quantity']} x TK ${item['unit_price']} = TK ${item['total_price']}'))
                  .toList(),
              pw.Divider(),
              pw.Text('Total: TK ${invoice['total_price'].toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Powered by GudamGuru',
                    style: pw.TextStyle(fontSize: 10)),
              )
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #: ${invoice['invoice_number']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(invoice['date_sold']))}',
            ),
            Text(
              'Time: ${DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(invoice['time_sold']))}',
            ),
            const SizedBox(height: 8),
            ...invoice['items'].map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                    '${item['product_id']} - ${item['name']}   :::   Quantity: ${item['quantity']} x ৳${item['unit_price']} = ৳${item['total_price']}'),
              );
            }).toList(),
            const Divider(),
            Text('Total: ৳${invoice['total_price'].toStringAsFixed(2)}'),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _exportInvoiceAsPdf(invoice),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Export PDF"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 198, 177, 255)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Image.asset('assets/images/logo.png', width: 150),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (UserSession().companyName ?? ''),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Invoices',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              _applyDateFilter();
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("Filter by Date"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by product ID or name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => _applyDateFilter(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredInvoices.isEmpty
                    ? const Center(child: Text('No invoices yet.'))
                    : ListView.builder(
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) =>
                            _buildInvoiceCard(filteredInvoices[index]),
                      ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Sales: ৳${_calculateTotalSales().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FloatingActionButton.extended(
                      onPressed: _exportAllInvoices,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Export All PDFs"),
                      backgroundColor: const Color.fromARGB(255, 217, 205, 255),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff000000),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          }
          if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const InventoryPage()));
          }
          if (index == 2) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReportAnalyticsPage()));
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
}
