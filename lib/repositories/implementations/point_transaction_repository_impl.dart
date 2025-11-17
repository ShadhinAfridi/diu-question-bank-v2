// repositories/implementations/point_transaction_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../models/base_model.dart';
import '../../models/point_transaction_model.dart';
import '../interfaces/point_transaction_repository.dart';
import '../../providers/cache_providers.dart';

class PointTransactionRepositoryImpl implements IPointTransactionRepository {
  final FirebaseFirestore _firestore;
  final PointTransactionCache _cache;

  @override
  final String userId;

  PointTransactionRepositoryImpl({
    required FirebaseFirestore firestore,
    required PointTransactionCache cache,
    required this.userId,
  }) : _firestore = firestore, _cache = cache;

  @override
  Future<PointTransaction?> get(String id) async {
    try {
      final cached = _cache.transactionBox.get(id);
      if (cached != null && await _cache.isCacheValid()) {
        debugPrint('PointTransactionRepository: Cache hit for transaction $id');
        return cached;
      }

      debugPrint('PointTransactionRepository: Cache miss for transaction $id');
      final doc = await _firestore
          .collection('point_transactions')
          .doc(id)
          .get();

      if (doc.exists) {
        final transaction = PointTransaction.fromFirestore(doc);
        await _cache.addTransactionWithCacheUpdate(transaction);
        await _cache.setLastSyncTime(DateTime.now());
        return transaction;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction $id: $e');
      return _cache.transactionBox.get(id);
    }
  }

  @override
  Future<List<PointTransaction>> getAll() async {
    try {
      final cachedTransactions = _getUserTransactions();
      if (cachedTransactions.isNotEmpty && await _cache.isCacheValid()) {
        debugPrint('PointTransactionRepository: Using ${cachedTransactions.length} cached transactions');
        return _sortTransactions(cachedTransactions);
      }

      debugPrint('PointTransactionRepository: Loading transactions from Firestore');
      return await _loadUserTransactionsFromFirestore();
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      return _sortTransactions(_getUserTransactions());
    }
  }

  @override
  Future<void> save(PointTransaction transaction) async {
    try {
      final updatedTransaction = PointTransaction(
        id: transaction.id,
        userId: transaction.userId,
        points: transaction.points,
        type: transaction.type,
        description: transaction.description,
        referenceId: transaction.referenceId,
        category: transaction.category,
        balanceAfter: transaction.balanceAfter,
        createdAt: transaction.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        version: transaction.version + 1,
      );

      await _firestore
          .collection('point_transactions')
          .doc(transaction.id)
          .set(updatedTransaction.toFirestore());

      await _cache.addTransactionWithCacheUpdate(updatedTransaction.copyWith(syncStatus: SyncStatus.synced));
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Error saving transaction: $e');

      // Save to cache with pending status
      final offlineTransaction = transaction.copyWith(
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );
      await _cache.addTransactionWithCacheUpdate(offlineTransaction);

      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _firestore.collection('point_transactions').doc(id).delete();
      await _cache.transactionBox.delete(id);
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  @override
  Stream<List<PointTransaction>> watchAll() {
    return _cache.transactionBox.watch().map((event) => _sortTransactions(_getUserTransactions()));
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      await _loadUserTransactionsFromFirestore();
    } catch (e) {
      debugPrint('Error syncing transactions: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    await _cache.transactionBox.clear();
    await _cache.clearCache();
  }

  @override
  Future<void> addEarnedPoints({
    required int points,
    required String description,
    String? referenceId,
    String category = 'general',
  }) async {
    try {
      final currentBalance = await getCurrentBalance();
      final transaction = PointTransaction(
        id: _generateTransactionId(),
        userId: userId,
        points: points,
        type: 'earn',
        description: description,
        referenceId: referenceId,
        category: category,
        balanceAfter: currentBalance + points,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        version: 0,
      );
      await save(transaction);
    } catch (e) {
      debugPrint('Error adding earned points: $e');
      rethrow;
    }
  }

  @override
  Future<void> addSpentPoints({
    required int points,
    required String description,
    required String referenceId,
    String category = 'general',
  }) async {
    try {
      final currentBalance = await getCurrentBalance();
      if (currentBalance < points) {
        throw Exception('Insufficient points');
      }

      final transaction = PointTransaction(
        id: _generateTransactionId(),
        userId: userId,
        points: points,
        type: 'spend',
        description: description,
        referenceId: referenceId,
        category: category,
        balanceAfter: currentBalance - points,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        version: 0,
      );
      await save(transaction);
    } catch (e) {
      debugPrint('Error adding spent points: $e');
      rethrow;
    }
  }

  @override
  Future<List<PointTransaction>> getRecentTransactions({int limit = 10}) async {
    final transactions = await _cache.getRecentUserTransactions(userId, limit: limit);
    if (transactions.isNotEmpty && await _cache.isCacheValid()) {
      return transactions;
    }

    final allTransactions = await getAll();
    return allTransactions.take(limit).toList();
  }

  @override
  Future<int> getTotalPointsEarned() async {
    // Try cache first
    final cachedBalance = await _cache.getCachedBalance(userId);
    if (await _cache.isCacheValid()) {
      final transactions = _getUserTransactions();
      final earned = transactions.where((t) => t.isEarned).fold<int>(0, (sum, t) => sum + t.points);
      return earned;
    }

    final transactions = await getAll();
    return transactions
        .where((t) => t.isEarned)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);
  }

  @override
  Future<int> getTotalPointsSpent() async {
    final transactions = await getAll();
    return transactions
        .where((t) => t.isSpent)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);
  }

  @override
  Future<int> getCurrentBalance() async {
    // Try cache first for quick response
    final cachedBalance = await _cache.getCachedBalance(userId);
    if (await _cache.isCacheValid()) {
      return cachedBalance;
    }

    // Calculate from all transactions
    final earned = await getTotalPointsEarned();
    final spent = await getTotalPointsSpent();
    return earned - spent;
  }

  @override
  void dispose() {
    _cache.transactionBox.close();
  }

  // ============ PRIVATE METHODS ============

  List<PointTransaction> _getUserTransactions() {
    return _cache.transactionBox.values
        .where((transaction) => transaction.userId == userId)
        .toList();
  }

  Future<List<PointTransaction>> _loadUserTransactionsFromFirestore() async {
    final querySnapshot = await _firestore
        .collection('point_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final transactions = querySnapshot.docs
        .map((doc) => PointTransaction.fromFirestore(doc))
        .toList();

    // Batch update cache
    for (final transaction in transactions) {
      await _cache.addTransactionWithCacheUpdate(transaction);
    }
    await _cache.setLastSyncTime(DateTime.now());

    return _sortTransactions(transactions);
  }

  List<PointTransaction> _sortTransactions(List<PointTransaction> transactions) {
    return transactions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _generateTransactionId() {
    return 'pt_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}';
  }
}