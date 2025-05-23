// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'header&nav.dart';
import 'database_helper.dart';
import 'UserSession.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';

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
                  style: const pw.TextStyle(fontSize: 10)),
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
                    style: const pw.TextStyle(fontSize: 10)),
              )
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : vibrantBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white : brightBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla
                  ? 'চালান নং: ${invoice['invoice_number']}'
                  : 'Invoice #: ${invoice['invoice_number']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              isBangla
                  ? 'তারিখ: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(invoice['date_sold']))}'
                  : 'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(invoice['date_sold']))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              isBangla
                  ? 'সময়: ${DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(invoice['time_sold']))}'
                  : 'Time: ${DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(invoice['time_sold']))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...invoice['items'].map<Widget>((item) {
              final quantity = item['quantity'];
              final unitPrice = item['unit_price'];
              final total = item['total_price'];
              final label = isBangla
                  ? '${item['product_id']} - ${item['name']}   :::   পরিমাণ: $quantity x ৳$unitPrice = ৳$total'
                  : '${item['product_id']} - ${item['name']}   :::   Quantity: $quantity x ৳$unitPrice = ৳$total';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            const Divider(),
            Text(
              isBangla
                  ? 'মোট: ৳${invoice['total_price'].toStringAsFixed(2)}'
                  : 'Total: ৳${invoice['total_price'].toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _exportInvoiceAsPdf(invoice),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  isBangla ? "পিডিএফ রপ্তানি" : "Export PDF",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? darkShade1 : brightBlue,
                  side: BorderSide(
                    color: isDark ? darkShade3 : deepIndigo,
                    width: 1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(240, 0, 0, 0)
          : const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  opacity: 0.1,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 10),
              children: [
                buildHeader(context),
                const SizedBox(height: 10),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: isBangla
                          ? 'পণ্য আইডি বা নাম দিয়ে খুঁজুন'
                          : 'Search by product ID or name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark ? darkShade2 : deepIndigo,
                            width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark ? darkShade2 : deepIndigo,
                            width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark
                                ? darkShade3
                                : const Color.fromARGB(255, 13, 0, 255),
                            width: 2),
                      ),
                    ),
                    onChanged: (_) => _applyDateFilter(),
                  ),
                ),

                const SizedBox(height: 10),

                // Header & Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isBangla ? 'চালান তালিকা' : 'Invoices',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isDark ? Colors.white : deepIndigo,
                          ),
                          label: Text(
                            isBangla
                                ? "তারিখ দিয়ে ফিল্টার করুন"
                                : "Filter by Date",
                            style: TextStyle(
                              color: isDark ? Colors.white : deepIndigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Invoices List
                if (filteredInvoices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        isBangla ? 'এখনও কোনো চালান নেই।' : 'No invoices yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredInvoices
                      .map((invoice) => _buildInvoiceCard(invoice))
                      .toList(),

                const SizedBox(height: 20),

                // Total Sales & Export Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBangla
                            ? 'মোট বিক্রি: ৳${_calculateTotalSales().toStringAsFixed(2)}'
                            : 'Total Sales: ৳${_calculateTotalSales().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FloatingActionButton.extended(
                        onPressed: _exportAllInvoices,
                        icon: const Icon(Icons.picture_as_pdf,
                            color: Colors.white),
                        label: Text(
                          isBangla ? "সব পিডিএফ রপ্তানি" : "Export All PDF'S",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: isDark ? darkShade3 : deepIndigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isDark ? darkShade1 : brightBlue,
                            width: 1,
                          ),
                        ),
                      ),
                    ],
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
}
