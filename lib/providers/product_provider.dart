import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class ProductProvider with ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  Map<String, dynamic>? _dashboardStats;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> loadProducts() async {
    _products = await DatabaseHelper.instance.getAllProducts();
    _updateLowStockProducts();
    notifyListeners();
  }

  void _updateLowStockProducts() {
    _lowStockProducts = _products.where((product) {
      return product['quantity'] <= product['min_stock_level'];
    }).toList();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await loadProducts();
  }

  Future<void> loadDashboardStats() async {
    _dashboardStats = await DatabaseHelper.instance.getDashboardStats();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await DatabaseHelper.instance
        .getSalesByDateRange(startDate, endDate);
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    return await DatabaseHelper.instance.getTopProducts(limit);
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await loadProducts();
    await loadDashboardStats();
  }
}
