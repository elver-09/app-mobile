import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Cola local persistente de escaneos de recojo (offline-first).
///
/// Cada escaneo se guarda aquí apenas se lee, así funciona sin señal y
/// sobrevive a cierres de la app. Cuando hay conexión, el worker de sync
/// envía los pendientes y actualiza su estado.
class PickupScan {
  final String uuid;
  final int storeId;
  final String code;
  final DateTime scannedAt;

  /// pending | synced | error
  String status;
  String orderNumber;
  String fullname;
  bool created;
  String errorMsg;

  PickupScan({
    required this.uuid,
    required this.storeId,
    required this.code,
    required this.scannedAt,
    this.status = 'pending',
    this.orderNumber = '',
    this.fullname = '',
    this.created = false,
    this.errorMsg = '',
  });

  Map<String, Object?> toMap() => {
        'uuid': uuid,
        'store_id': storeId,
        'code': code,
        'scanned_at': scannedAt.toIso8601String(),
        'status': status,
        'order_number': orderNumber,
        'fullname': fullname,
        'created': created ? 1 : 0,
        'error_msg': errorMsg,
      };

  factory PickupScan.fromMap(Map<String, Object?> m) => PickupScan(
        uuid: m['uuid'] as String,
        storeId: (m['store_id'] as int?) ?? 0,
        code: (m['code'] as String?) ?? '',
        scannedAt: DateTime.tryParse((m['scanned_at'] as String?) ?? '') ??
            DateTime.now(),
        status: (m['status'] as String?) ?? 'pending',
        orderNumber: (m['order_number'] as String?) ?? '',
        fullname: (m['fullname'] as String?) ?? '',
        created: ((m['created'] as int?) ?? 0) == 1,
        errorMsg: (m['error_msg'] as String?) ?? '',
      );
}

class PickupQueueDb {
  PickupQueueDb._();
  static final PickupQueueDb instance = PickupQueueDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'pickup_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE pending_scans (
            uuid         TEXT PRIMARY KEY,
            store_id     INTEGER NOT NULL,
            code         TEXT NOT NULL,
            scanned_at   TEXT NOT NULL,
            status       TEXT NOT NULL DEFAULT 'pending',
            order_number TEXT DEFAULT '',
            fullname     TEXT DEFAULT '',
            created      INTEGER DEFAULT 0,
            error_msg    TEXT DEFAULT ''
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_store_status ON pending_scans(store_id, status)');
      },
    );
    return _db!;
  }

  Future<void> insert(PickupScan scan) async {
    final db = await _database;
    await db.insert('pending_scans', scan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Todos los escaneos de una tienda, del más reciente al más antiguo.
  Future<List<PickupScan>> itemsForStore(int storeId) async {
    final db = await _database;
    final rows = await db.query(
      'pending_scans',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'scanned_at DESC',
    );
    return rows.map(PickupScan.fromMap).toList();
  }

  /// Pendientes (o con error) listos para reintentar, en orden de escaneo.
  Future<List<PickupScan>> pendingForStore(int storeId) async {
    final db = await _database;
    final rows = await db.query(
      'pending_scans',
      where: 'store_id = ? AND status IN (?, ?)',
      whereArgs: [storeId, 'pending', 'error'],
      orderBy: 'scanned_at ASC',
    );
    return rows.map(PickupScan.fromMap).toList();
  }

  Future<int> countByStatus(int storeId, String status) async {
    final db = await _database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM pending_scans WHERE store_id = ? AND status = ?',
      [storeId, status],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// ¿Existe ya ese código en la tienda (no en error)? Para deduplicar.
  Future<bool> existsCode(int storeId, String codeUpper) async {
    final db = await _database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pending_scans "
      "WHERE store_id = ? AND UPPER(code) = ? AND status != 'error'",
      [storeId, codeUpper],
    );
    return (Sqflite.firstIntValue(r) ?? 0) > 0;
  }

  Future<void> updateResult(
    String uuid, {
    required String status,
    String orderNumber = '',
    String fullname = '',
    bool created = false,
    String errorMsg = '',
  }) async {
    final db = await _database;
    await db.update(
      'pending_scans',
      {
        'status': status,
        'order_number': orderNumber,
        'fullname': fullname,
        'created': created ? 1 : 0,
        'error_msg': errorMsg,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> clearStore(int storeId) async {
    final db = await _database;
    await db.delete('pending_scans', where: 'store_id = ?', whereArgs: [storeId]);
  }
}
