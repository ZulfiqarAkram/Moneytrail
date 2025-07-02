import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart' as models;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'money_trail_fresh.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        colorValue INTEGER NOT NULL DEFAULT 0xFF2196F3,
        isEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }



  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Income categories
      models.Category(name: 'Salary', type: 'income', colorValue: 0xFF4CAF50, isEnabled: true),
      models.Category(name: 'Freelance', type: 'income', colorValue: 0xFF8BC34A, isEnabled: true),
      models.Category(name: 'Investment', type: 'income', colorValue: 0xFF9C27B0, isEnabled: true),
      models.Category(name: 'Other Income', type: 'income', colorValue: 0xFF607D8B, isEnabled: true),
      
      // Expense categories
      models.Category(name: 'Food & Dining', type: 'expense', colorValue: 0xFFFF5722, isEnabled: true),
      models.Category(name: 'Transportation', type: 'expense', colorValue: 0xFF2196F3, isEnabled: true),
      models.Category(name: 'Shopping', type: 'expense', colorValue: 0xFFE91E63, isEnabled: true),
      models.Category(name: 'Entertainment', type: 'expense', colorValue: 0xFF9C27B0, isEnabled: true),
      models.Category(name: 'Bills & Utilities', type: 'expense', colorValue: 0xFFFF9800, isEnabled: true),
      models.Category(name: 'Health & Medical', type: 'expense', colorValue: 0xFFF44336, isEnabled: true),
      models.Category(name: 'Education', type: 'expense', colorValue: 0xFF3F51B5, isEnabled: true),
      models.Category(name: 'Other Expense', type: 'expense', colorValue: 0xFF795548, isEnabled: true),
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }



  // Category operations
  Future<int> insertCategory(models.Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<models.Category>> getCategories({String? type, bool? enabledOnly}) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (type != null) {
      conditions.add('type = ?');
      whereArgs.add(type);
    }
    
    if (enabledOnly == true) {
      conditions.add('isEnabled = 1');
    }
    
    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    
    final maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => models.Category.fromMap(maps[i]));
  }

  Future<models.Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return models.Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(models.Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleCategoryStatus(int id, bool isEnabled) async {
    final db = await database;
    return await db.update(
      'categories',
      {'isEnabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasCategoryTransactions(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> recreateDefaultCategories() async {
    final db = await database;
    await _insertDefaultCategories(db);
  }

  // Transaction operations
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<models.Transaction>> getTransactions({
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    List<String> conditions = [];

    if (type != null) {
      conditions.add('type = ?');
      whereArgs.add(type);
    }

    if (categoryId != null) {
      conditions.add('categoryId = ?');
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      conditions.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      conditions.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  Future<models.Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return models.Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Utility methods for dashboard
  Future<Map<String, double>> getCategoryTotals({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = '''
      SELECT c.name, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
    ''';

    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (type != null) {
      conditions.add('t.type = ?');
      whereArgs.add(type);
    }

    if (startDate != null) {
      conditions.add('t.date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      conditions.add('t.date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }

    query += ' GROUP BY t.categoryId, c.name';

    final results = await db.rawQuery(query, whereArgs);
    Map<String, double> categoryTotals = {};

    for (var result in results) {
      categoryTotals[result['name'] as String] = result['total'] as double;
    }

    return categoryTotals;
  }

  Future<List<Map<String, dynamic>>> getDailyTotals({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = '''
      SELECT DATE(date/1000, 'unixepoch') as date, SUM(amount) as total
      FROM transactions
    ''';

    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (type != null) {
      conditions.add('type = ?');
      whereArgs.add(type);
    }

    if (startDate != null) {
      conditions.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      conditions.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }

    query += ' GROUP BY DATE(date/1000, \'unixepoch\') ORDER BY date';

    return await db.rawQuery(query, whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
} 