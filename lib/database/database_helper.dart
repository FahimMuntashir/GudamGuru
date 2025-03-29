import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      print('Using existing database connection');
      return _database!;
    }
    print('Initializing new database connection');
    _database = await _initDB('gudam_guru.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      print('Database path: $dbPath');
      final path = join(dbPath, filePath);
      print('Full database path: $path');

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) => print('Database opened successfully'),
      );
      print('Database initialized successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    print('Creating database tables...');
    try {
      // Users table
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          password TEXT NOT NULL,
          company_name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          address TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      print('Users table created successfully');

      // Products table
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT,
          purchase_price REAL NOT NULL,
          selling_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          min_stock_level INTEGER DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      print('Products table created successfully');

      // Transactions table
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          type TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          total_amount REAL NOT NULL,
          date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
      print('Transactions table created successfully');
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  // User operations
  Future<bool> authenticateUser(String id, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [id, password],
    );
    return result.isNotEmpty;
  }

  Future<bool> createUser(Map<String, dynamic> user) async {
    try {
      print('Attempting to create user: ${user['id']}');
      final db = await database;

      // Check if user already exists
      final existingUser = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [user['id']],
      );

      if (existingUser.isNotEmpty) {
        print('User ${user['id']} already exists');
        return false;
      }

      await db.insert('users', user);
      print('User ${user['id']} created successfully');
      return true;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Product operations
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'transactions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );
  }

  // Analytics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    // Get total products
    final totalProducts = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM products')) ??
        0;

    // Get low stock items
    final lowStockItems = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM products 
        WHERE quantity <= min_stock_level
      ''')) ?? 0;

    // Get total sales today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final totalSalesToday = (Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) 
        FROM transactions 
        WHERE type = 'sale' AND date >= ?
      ''', [startOfDay.toIso8601String()])) ?? 0).toDouble();

    return {
      'total_products': totalProducts,
      'low_stock_items': lowStockItems,
      'total_sales_today': totalSalesToday,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        date(date) as sale_date,
        SUM(total_amount) as total_sales
      FROM transactions
      WHERE type = 'sale' 
      AND date BETWEEN ? AND ?
      GROUP BY date(date)
      ORDER BY sale_date
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.name,
        COUNT(t.id) as transaction_count,
        SUM(t.quantity) as total_quantity,
        SUM(t.total_amount) as total_revenue
      FROM products p
      LEFT JOIN transactions t ON p.id = t.product_id
      WHERE t.type = 'sale'
      GROUP BY p.id
      ORDER BY total_revenue DESC
      LIMIT ?
    ''', [limit]);
  }
}
