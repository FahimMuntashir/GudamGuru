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
}
