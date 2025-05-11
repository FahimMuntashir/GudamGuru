import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'UserSession.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'gudamguru.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT,
        low_stock_alert INTEGER,
        description TEXT,
        image_path TEXT,
        brand_name TEXT,
        user_id TEXT NOT NULL,
        date_added TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        description TEXT,
        date_added TEXT,
        user_id TEXT NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(product_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        user_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        date_returned TEXT NOT NULL,
        user_id TEXT NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(product_id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          user_id TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS returns (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          reason TEXT NOT NULL,
          date_returned TEXT NOT NULL,
          user_id TEXT NOT NULL,
          FOREIGN KEY(product_id) REFERENCES products(product_id)
        )
      ''');
    }
  }

  //invoices.dart
  Future<List<Map<String, dynamic>>> getAllSales() async {
    final dbClient = await database;
    final userId = UserSession().userId;

    return await dbClient.query('sales',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date_sold DESC, time_sold DESC');
  }

//sell.dart begins
  // Future<void> insertSale(Map<String, dynamic> saleData) async {
  //   final dbClient = await database;

  //   await dbClient.execute('''
  //   CREATE TABLE IF NOT EXISTS sales (
  //     id INTEGER PRIMARY KEY AUTOINCREMENT,
  //     invoice_number TEXT,
  //     product_id TEXT,
  //     name TEXT,
  //     quantity INTEGER,
  //     unit_price REAL,
  //     total_price REAL,
  //     date_sold TEXT,
  //     time_sold TEXT,
  //     user_id TEXT
  //   )
  // ''');

  //   // Generate invoice number and time
  //   String timeOnly =
  //       DateTime.now().toLocal().toString().split(' ')[1].split('.')[0];
  //   String invoiceNumber = 'INV${DateTime.now().millisecondsSinceEpoch}';

  //   // Fetch product name if not already present
  // if (saleData['name'] == null || saleData['name'].toString().isEmpty) {
  //   final product = await getProductById(saleData['product_id'] ?? '');
  //   saleData['name'] = product?['name'] ?? 'Unnamed';
  // }

  // saleData['invoice_number'] = invoiceNumber;
  // saleData['time_sold'] = timeOnly;
  // saleData['user_id'] = UserSession().userId;

  //   await dbClient.insert('sales', saleData);
  // }
  Future<void> insertSale(Map<String, dynamic> saleData) async {
    final dbClient = await database;

    await dbClient.execute('''
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT,
      product_id TEXT,
      name TEXT,
      quantity INTEGER,
      unit_price REAL,
      purchase_price REAL,
      total_price REAL,
      date_sold TEXT,
      time_sold TEXT,
      user_id TEXT
    )
  ''');

    if (saleData['name'] == null || saleData['name'].toString().isEmpty) {
      final product = await getProductById(saleData['product_id'] ?? '');
      saleData['name'] = product?['name'] ?? 'Unnamed';
    }

    saleData['user_id'] = UserSession().userId;

    await dbClient.insert('sales', saleData);
  }

  Future<void> updateStockEntryQuantity(int id, int newQuantity) async {
    final dbClient = await database;
    await dbClient.update(
      'stock_entries',
      {'quantity': newQuantity},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, UserSession().userId],
    );
  }

  Future<void> decreaseProductQuantity(String productId, int quantity) async {
    final dbClient = await database;
    await dbClient.rawUpdate('''
    UPDATE products
    SET quantity = quantity - ?
    WHERE product_id = ? AND user_id = ?
  ''', [quantity, productId, UserSession().userId]);
  }
//sell.dart ends

  // Future<int> insertProduct(Map<String, dynamic> product) async {
  //   final dbClient = await database;
  //   product['user_id'] = UserSession().userId;
  //   product['date_added'] ??= DateTime.now().toIso8601String();
  //   return await dbClient.insert(
  //     'products',
  //     product,
  //     conflictAlgorithm: ConflictAlgorithm.replace,
  //   );
  // }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final dbClient = await database;
    product['user_id'] = UserSession().userId;
    product['date_added'] ??= DateTime.now().toIso8601String();

    int result = await dbClient.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    //Add initial stock as a stock entry
    await insertStockEntry({
      'product_id': product['product_id'],
      'purchase_price': product['purchase_price'],
      'quantity': product['quantity'],
      'description': product['description'] ?? '',
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final dbClient = await database;
    final userId = UserSession().userId;
    return await dbClient.query(
      'products',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateProduct(
      String productId, Map<String, dynamic> updatedFields) async {
    final dbClient = await database;
    return await dbClient.update(
      'products',
      updatedFields,
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, UserSession().userId],
    );
  }

  Future<Map<String, dynamic>?> getProductById(String productId) async {
    final dbClient = await database;
    List<Map<String, dynamic>> result = await dbClient.query(
      'products',
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, UserSession().userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteProduct(String productId) async {
    final dbClient = await database;
    return await dbClient.delete(
      'products',
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, UserSession().userId],
    );
  }

  Future<int> insertStockEntry(Map<String, dynamic> entry) async {
    final dbClient = await database;
    entry['user_id'] = UserSession().userId;
    entry['date_added'] = DateTime.now().toIso8601String();
    return await dbClient.insert('stock_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getStockEntriesForProduct(
      String productId) async {
    final dbClient = await database;
    return await dbClient.query(
      'stock_entries',
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, UserSession().userId],
      orderBy: 'date_added ASC',
    );
  }

  Future<void> updateProductQuantity(String productId, int addedQty) async {
    final dbClient = await database;
    await dbClient.rawUpdate('''
      UPDATE products
      SET quantity = quantity + ?
      WHERE product_id = ? AND user_id = ?
    ''', [addedQty, productId, UserSession().userId]);
  }

  // Notes related methods
  Future<int> insertNote(Map<String, dynamic> note) async {
    final dbClient = await database;
    note['user_id'] = UserSession().userId;
    note['timestamp'] = DateTime.now().toIso8601String();
    note['completed'] = note['completed'] == 'true' ? 1 : 0;
    return await dbClient.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final dbClient = await database;
    final userId = UserSession().userId;
    return await dbClient.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateNote(int id, Map<String, dynamic> updatedFields) async {
    final dbClient = await database;
    if (updatedFields.containsKey('completed')) {
      updatedFields['completed'] = updatedFields['completed'] == 'true' ? 1 : 0;
    }
    return await dbClient.update(
      'notes',
      updatedFields,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, UserSession().userId],
    );
  }

  Future<int> deleteNote(int id) async {
    final dbClient = await database;
    return await dbClient.delete(
      'notes',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, UserSession().userId],
    );
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final dbClient = await database;
    final userId = UserSession().userId;
    return await dbClient.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(quantity) FROM stock_entries 
              WHERE product_id = p.product_id AND user_id = ?) as total_stock
      FROM products p
      WHERE p.user_id = ? 
        AND p.low_stock_alert IS NOT NULL 
        AND (SELECT SUM(quantity) FROM stock_entries 
             WHERE product_id = p.product_id AND user_id = ?) <= p.low_stock_alert
      ORDER BY total_stock ASC
    ''', [userId, userId, userId]);
  }

  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final dbClient = await database;
    final userId = UserSession().userId;
    return await dbClient.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(quantity) FROM stock_entries 
              WHERE product_id = p.product_id AND user_id = ?) as total_stock
      FROM products p
      WHERE p.user_id = ? 
        AND (SELECT SUM(quantity) FROM stock_entries 
             WHERE product_id = p.product_id AND user_id = ?) = 0
      ORDER BY p.name ASC
    ''', [userId, userId, userId]);
  }

  Future<Map<String, dynamic>> getStockSummary() async {
    final dbClient = await database;
    final userId = UserSession().userId;

    // Get total stock value
    final totalValue = await dbClient.rawQuery('''
      SELECT SUM(se.quantity * p.purchase_price) as total_value
      FROM stock_entries se
      JOIN products p ON se.product_id = p.product_id
      WHERE se.user_id = ?
    ''', [userId]);

    // Get fastest moving products (top 5 by sales in last 30 days)
    final fastestMoving = await dbClient.rawQuery('''
      SELECT p.name, SUM(s.quantity) as total_sold
      FROM sales s
      JOIN products p ON s.product_id = p.product_id
      WHERE s.user_id = ? 
        AND s.date_sold >= date('now', '-30 days')
      GROUP BY p.product_id
      ORDER BY total_sold DESC
      LIMIT 5
    ''', [userId]);

    // Get slow moving products (no sales in last 90 days)
    final slowMoving = await dbClient.rawQuery('''
      SELECT p.name
      FROM products p
      LEFT JOIN sales s ON p.product_id = s.product_id 
        AND s.user_id = ? 
        AND s.date_sold >= date('now', '-90 days')
      WHERE p.user_id = ? 
        AND s.id IS NULL
      ORDER BY p.name ASC
    ''', [userId, userId]);

    return {
      'total_value': totalValue.first['total_value'] ?? 0,
      'fastest_moving': fastestMoving.map((p) => p['name'] as String).toList(),
      'slow_moving': slowMoving.map((p) => p['name'] as String).toList(),
    };
  }

  // Returns related methods
  Future<int> insertReturn(Map<String, dynamic> returnData) async {
    final dbClient = await database;
    returnData['user_id'] = UserSession().userId;
    return await dbClient.insert('returns', returnData);
  }

  Future<void> increaseProductQuantity(String productId, int quantity) async {
    final dbClient = await database;
    await dbClient.rawUpdate('''
      UPDATE products
      SET quantity = quantity + ?
      WHERE product_id = ? AND user_id = ?
    ''', [quantity, productId, UserSession().userId]);
  }

  Future<List<Map<String, dynamic>>> getAllReturns() async {
    final dbClient = await database;
    final userId = UserSession().userId;
    return await dbClient.rawQuery('''
      SELECT r.*, p.name as product_name
      FROM returns r
      JOIN products p ON r.product_id = p.product_id
      WHERE r.user_id = ?
      ORDER BY r.date_returned DESC
    ''', [userId]);
  }
}
