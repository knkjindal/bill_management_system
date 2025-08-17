import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/transaction_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'accounting_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE parties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            balance REAL,
            isCreditor INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity INTEGER,
            purchasePrice REAL,
            sellingPrice REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            partyId INTEGER,
            itemId INTEGER,
            quantity INTEGER,
            amount REAL,
            date TEXT,
            isCredit INTEGER,
            type TEXT,
            note TEXT,
            tags TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Use try-catch to avoid crash if columns already exist
          try {
            await db.execute("ALTER TABLE transactions ADD COLUMN type TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE transactions ADD COLUMN note TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE transactions ADD COLUMN tags TEXT");
          } catch (_) {}
        }
      },
    );
  }

  // ------------------- Party CRUD -------------------

  static Future<int> insertParty(Party party) async {
    final dbClient = await db;
    return await dbClient.insert('parties', party.toMap());
  }

  static Future<List<Party>> getAllParties() async {
    final dbClient = await db;
    final result = await dbClient.query('parties');
    return result.map((e) => Party.fromMap(e)).toList();
  }

  static Future<Party> getPartyById(int id) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'parties',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Party.fromMap(result.first);
    } else {
      throw Exception('Party with id $id not found');
    }
  }

  static Future<int> updateParty(Party party) async {
    final dbClient = await db;
    return await dbClient.update(
      'parties',
      party.toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  static Future<int> deleteParty(int id) async {
    final dbClient = await db;
    return await dbClient.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Item CRUD -------------------

  static Future<int> insertItem(Item item) async {
    final dbClient = await db;
    return await dbClient.insert('items', item.toMap());
  }

  static Future<List<Item>> getAllItems() async {
    final dbClient = await db;
    final result = await dbClient.query('items');
    return result.map((e) => Item.fromMap(e)).toList();
  }

  static Future<int> updateItem(Item item) async {
    final dbClient = await db;
    return await dbClient.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<int> deleteItem(int id) async {
    final dbClient = await db;
    return await dbClient.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Transaction CRUD -------------------

  static Future<int> insertTransaction(TransactionModel txn) async {
    final dbClient = await db;
    return await dbClient.insert('transactions', txn.toMap());
  }

  static Future<List<TransactionModel>> getAllTransactions() async {
    final dbClient = await db;
    final result = await dbClient.query('transactions', orderBy: 'date DESC');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  static Future<List<TransactionModel>> getTransactionsForParty(int partyId) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'transactions',
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  static Future<int> deleteTransaction(int id) async {
    final dbClient = await db;
    return await dbClient.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Utility -------------------

  static Future<void> updatePartyBalance(int partyId, double newBalance) async {
    final dbClient = await db;
    await dbClient.update(
      'parties',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [partyId],
    );
  }

  static Future<void> updateItemQuantity(int itemId, int updatedQty) async {
    final dbClient = await db;
    await dbClient.update(
      'items',
      {'quantity': updatedQty},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
