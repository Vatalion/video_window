import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CartItems extends Table {
  TextColumn get id => text().unique()();
  TextColumn get cartId => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  TextColumn get imageUrl => text()();
  TextColumn get variantId => text().nullable()();
  TextColumn get customAttributes => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingCarts extends Table {
  TextColumn get id => text().unique()();
  TextColumn get userId => text()();
  TextColumn get sessionId => text()();
  BoolColumn get isAnonymous => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get shipping => real()();
  RealColumn get total => real()();
  TextColumn get currency => text()();
  TextColumn get couponCode => text().nullable()();
  RealColumn get discountAmount => real().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CartDatabase {
  late Database _db;

  Future<void> init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shopping_cart.sqlite'));
    _db = NativeDatabase(file);

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
      'id': item['id'],
      'productId': item['product_id'],
      'name': item['name'],
      'description': item['description'],
      'price': item['price'],
      'quantity': item['quantity'],
      'imageUrl': item['image_url'],
      'variantId': item['variant_id'],
      'customAttributes': item['custom_attributes'],
      'addedAt': DateTime.fromMillisecondsSinceEpoch(item['added_at']),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(item['updated_at']),
    }).toList();

    return {
      'id': cart['id'],
      'userId': cart['user_id'],
      'sessionId': cart['session_id'],
      'isAnonymous': cart['is_anonymous'] == 1,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(cart['created_at']),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(cart['updated_at']),
      'expiresAt': DateTime.fromMillisecondsSinceEpoch(cart['expires_at']),
      'subtotal': cart['subtotal'],
      'tax': cart['tax'],
      'shipping': cart['shipping'],
      'total': cart['total'],
      'currency': cart['currency'],
      'couponCode': cart['coupon_code'],
      'discountAmount': cart['discount_amount'],
      'syncStatus': cart['sync_status'],
      'lastSyncedAt': cart['last_synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(cart['last_synced_at'])
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
    return getCart(cartResult.first['id']);
  }

  Future<Map<String, dynamic>?> getCartBySession(String sessionId) async {
    final cartResult = await _db.query(
      'shopping_carts',
      where: {'session_id': sessionId},
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (cartResult.isEmpty) return null;
    return getCart(cartResult.first['id']);
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
      final fullCart = await getCart(cart['id']);
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