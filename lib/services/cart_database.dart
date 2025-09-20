import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

class _SimpleSqlDb {
  final sqlite.Database _db;

  _SimpleSqlDb(this._db);

  Future<void> customStatement(String sql, [List<Object?> params = const []]) async {
    final stmt = _db.prepare(sql);
    try {
      stmt.execute(params);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> transaction(Future<void> Function() action) async {
    try {
      _db.execute('BEGIN');
      await action();
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> insert(String table, Map<String, Object?> values) async {
    final cols = values.keys.toList();
    final placeholders = List.filled(cols.length, '?').join(', ');
    final sql = 'INSERT INTO $table (${cols.join(', ')}) VALUES ($placeholders)';
    final stmt = _db.prepare(sql);
    try {
      stmt.execute(cols.map((c) => values[c]).toList());
    } finally {
      stmt.dispose();
    }
  }

  Future<void> update(String table, Map<String, Object?> values, {required Map<String, Object?> where}) async {
    final setSql = values.keys.map((k) => '$k = ?').join(', ');
    final whereSql = where.keys.map((k) => '$k = ?').join(' AND ');
    final sql = 'UPDATE $table SET $setSql WHERE $whereSql';
    final stmt = _db.prepare(sql);
    try {
      stmt.execute([
        ...values.keys.map((k) => values[k]),
        ...where.keys.map((k) => where[k]),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> delete(String table, {required Map<String, Object?> where}) async {
    final whereSql = where.keys.map((k) => '$k = ?').join(' AND ');
    final sql = 'DELETE FROM $table WHERE $whereSql';
    final stmt = _db.prepare(sql);
    try {
      stmt.execute(where.keys.map((k) => where[k]).toList());
    } finally {
      stmt.dispose();
    }
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    int? limit,
  }) async {
    final buffer = StringBuffer('SELECT * FROM $table');
    final params = <Object?>[];
    if (where.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(where.keys.map((k) => '$k = ?').join(' AND '));
      params.addAll(where.keys.map((k) => where[k]));
    }
    if (orderBy != null) {
      buffer.write(' ORDER BY $orderBy');
    }
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }
    final result = _db.select(buffer.toString(), params);
    final columns = result.columnNames;
    return result.map((row) {
      final map = <String, Object?>{};
      for (var i = 0; i < columns.length; i++) {
        map[columns[i]] = row[i];
      }
      return map;
    }).toList();
  }

  Future<void> close() async {
    _db.dispose();
  }
}

class CartDatabase {
  late final _SimpleSqlDb _db;

  Future<void> init() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'shopping_cart.sqlite'));
  final sqliteDb = sqlite.sqlite3.open(file.path);
  _db = _SimpleSqlDb(sqliteDb);

    // Run migration
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS shopping_carts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        is_anonymous INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        shipping REAL NOT NULL,
        total REAL NOT NULL,
        currency TEXT NOT NULL,
        coupon_code TEXT,
        discount_amount REAL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at INTEGER
      )
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS cart_items (
        id TEXT PRIMARY KEY,
        cart_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        variant_id TEXT,
        custom_attributes TEXT,
        added_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (cart_id) REFERENCES shopping_carts (id) ON DELETE CASCADE
      )
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id)
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_carts_user_id ON shopping_carts(user_id)
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_carts_session_id ON shopping_carts(session_id)
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_carts_expires_at ON shopping_carts(expires_at)
    ''');
  }

  Future<void> saveCart(Map<String, dynamic> cart) async {
    await _db.transaction(() async {
      // Delete existing cart and items
      await _db.delete('shopping_carts', where: {'id': cart['id']});
      await _db.delete('cart_items', where: {'cart_id': cart['id']});

      // Insert cart
      await _db.insert('shopping_carts', {
        'id': cart['id'],
        'user_id': cart['userId'],
        'session_id': cart['sessionId'],
        'is_anonymous': cart['isAnonymous'] ? 1 : 0,
        'created_at': cart['createdAt'].millisecondsSinceEpoch,
        'updated_at': cart['updatedAt'].millisecondsSinceEpoch,
        'expires_at': cart['expiresAt'].millisecondsSinceEpoch,
        'subtotal': cart['subtotal'],
        'tax': cart['tax'],
        'shipping': cart['shipping'],
        'total': cart['total'],
        'currency': cart['currency'],
        'coupon_code': cart['couponCode'],
        'discount_amount': cart['discountAmount'],
        'sync_status': cart['syncStatus'] ?? 'pending',
        'last_synced_at': cart['lastSyncedAt']?.millisecondsSinceEpoch,
      });

      // Insert cart items
      for (final item in cart['items']) {
        await _db.insert('cart_items', {
          'id': item['id'],
          'cart_id': cart['id'],
          'product_id': item['productId'],
          'name': item['name'],
          'description': item['description'],
          'price': item['price'],
          'quantity': item['quantity'],
          'image_url': item['imageUrl'],
          'variant_id': item['variantId'],
          'custom_attributes': item['customAttributes'],
          'added_at': item['addedAt'].millisecondsSinceEpoch,
          'updated_at': item['updatedAt'].millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<Map<String, dynamic>?> getCart(String cartId) async {
    final cartResult = await _db.query(
      'shopping_carts',
      where: {'id': cartId},
    );

    if (cartResult.isEmpty) return null;

    final cart = cartResult.first;
    final itemsResult = await _db.query(
      'cart_items',
      where: {'cart_id': cartId},
    );

    final items = itemsResult.map((item) => {
      'id': item['id'] as String,
      'productId': item['product_id'] as String,
      'name': item['name'] as String,
      'description': item['description'] as String,
      'price': (item['price'] as num).toDouble(),
      'quantity': item['quantity'] as int,
      'imageUrl': item['image_url'] as String,
      'variantId': item['variant_id'] as String?,
      'customAttributes': item['custom_attributes'] as String?,
      'addedAt': DateTime.fromMillisecondsSinceEpoch(item['added_at'] as int),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(item['updated_at'] as int),
    }).toList();

    return {
    'id': cart['id'] as String,
    'userId': cart['user_id'] as String,
    'sessionId': cart['session_id'] as String,
      'isAnonymous': cart['is_anonymous'] == 1,
    'createdAt': DateTime.fromMillisecondsSinceEpoch(cart['created_at'] as int),
    'updatedAt': DateTime.fromMillisecondsSinceEpoch(cart['updated_at'] as int),
    'expiresAt': DateTime.fromMillisecondsSinceEpoch(cart['expires_at'] as int),
    'subtotal': (cart['subtotal'] as num).toDouble(),
    'tax': (cart['tax'] as num).toDouble(),
    'shipping': (cart['shipping'] as num).toDouble(),
    'total': (cart['total'] as num).toDouble(),
    'currency': cart['currency'] as String,
    'couponCode': cart['coupon_code'] as String?,
    'discountAmount': (cart['discount_amount'] as num?)?.toDouble(),
    'syncStatus': cart['sync_status'] as String,
    'lastSyncedAt': cart['last_synced_at'] != null
      ? DateTime.fromMillisecondsSinceEpoch(cart['last_synced_at'] as int)
          : null,
      'items': items,
    };
  }

  Future<Map<String, dynamic>?> getCartByUser(String userId) async {
    final cartResult = await _db.query(
      'shopping_carts',
      where: {'user_id': userId},
      orderBy: 'updated_at DESC',
      limit: 1,
    );

  if (cartResult.isEmpty) return null;
  return getCart(cartResult.first['id'] as String);
  }

  Future<Map<String, dynamic>?> getCartBySession(String sessionId) async {
    final cartResult = await _db.query(
      'shopping_carts',
      where: {'session_id': sessionId},
      orderBy: 'updated_at DESC',
      limit: 1,
    );

  if (cartResult.isEmpty) return null;
  return getCart(cartResult.first['id'] as String);
  }

  Future<void> deleteCart(String cartId) async {
    await _db.transaction(() async {
      await _db.delete('cart_items', where: {'cart_id': cartId});
      await _db.delete('shopping_carts', where: {'id': cartId});
    });
  }

  Future<void> updateSyncStatus(String cartId, String status, {DateTime? syncedAt}) async {
    await _db.update(
      'shopping_carts',
      {
        'sync_status': status,
        'last_synced_at': syncedAt?.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: {'id': cartId},
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncCarts() async {
    final cartsResult = await _db.query(
      'shopping_carts',
      where: {'sync_status': 'pending'},
    );

    final carts = <Map<String, dynamic>>[];
    for (final cart in cartsResult) {
  final fullCart = await getCart(cart['id'] as String);
      if (fullCart != null) {
        carts.add(fullCart);
      }
    }

    return carts;
  }

  Future<void> cleanupExpiredCarts() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      // Delete expired cart items
      await _db.customStatement('''
        DELETE FROM cart_items
        WHERE cart_id IN (
          SELECT id FROM shopping_carts
          WHERE expires_at < ?
        )
      ''', [now]);

      // Delete expired carts
      await _db.customStatement('''
        DELETE FROM shopping_carts
        WHERE expires_at < ?
      ''', [now]);
    });
  }

  Future<void> close() async {
    await _db.close();
  }
}