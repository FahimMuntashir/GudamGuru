import 'package:flutter/material.dart';

import 'database_helper.dart';

class ReturnItemPage extends StatefulWidget {
  const ReturnItemPage({super.key});

  @override
  State<ReturnItemPage> createState() => _ReturnItemPageState();
}

class _ReturnItemPageState extends State<ReturnItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  Map<String, dynamic>? _selectedProduct;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await DatabaseHelper().getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processReturn() async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      try {
        final quantity = int.parse(_quantityController.text);
        final reason = _reasonController.text;

        // Add to returns table
        await DatabaseHelper().insertReturn({
          'product_id': _selectedProduct!['product_id'],
          'quantity': quantity,
          'reason': reason,
          'date_returned': DateTime.now().toIso8601String(),
        });

        // Update stock
        await DatabaseHelper().increaseProductQuantity(
          _selectedProduct!['product_id'],
          quantity,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item returned successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error processing return: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing return: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Item'),
        backgroundColor: const Color(0xFF211C84),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Selection
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'Select Product',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProduct,
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text(product['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProduct = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a product';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity Input
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Return Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Reason Input
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Return',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason for return';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
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

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
