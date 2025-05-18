import 'package:flutter/material.dart';

import 'database_helper.dart';

class ReturnItemPage extends StatefulWidget {
  const ReturnItemPage({super.key});

  @override
  State<ReturnItemPage> createState() => _ReturnItemPageState();
}

class _ReturnItemPageState extends State<ReturnItemPage> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  String? _quantity;
  String? _reason;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = DatabaseHelper();
    final products = await db.getAllProducts();
    setState(() {
      _products = products;
      if (_selectedProductId == null && products.isNotEmpty) {
        _selectedProductId = products.first['product_id'].toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Item'),
        backgroundColor: const Color(0xFF211C84),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                items: _products.map((product) {
                  return DropdownMenuItem<String>(
                    value: product['product_id'].toString(),
                    child: Text(product['name']),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Return Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  if (int.tryParse(value) == null || int.parse(value) <= 0)
                    return 'Enter a valid quantity';
                  return null;
                },
                onSaved: (value) => _quantity = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reason for Return',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a reason' : null,
                onSaved: (value) => _reason = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _processReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF211C84),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Process Return'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processReturn() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final selectedProduct = _products
        .firstWhere((p) => p['product_id'].toString() == _selectedProductId);
    final db = DatabaseHelper();
    await db.insertReturn({
      'product_id': int.parse(_selectedProductId!),
      'quantity': int.parse(_quantity!),
      'reason': _reason,
      'date_returned': DateTime.now().toIso8601String(),
      'user_id': 'admin', // Replace with actual user id if available
    });
    await db.increaseProductQuantity(
        _selectedProductId!, int.parse(_quantity!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return processed successfully')),
    );
    setState(() {
      _selectedProductId = null;
      _quantity = null;
      _reason = null;
    });
    _formKey.currentState!.reset();
  }
}
