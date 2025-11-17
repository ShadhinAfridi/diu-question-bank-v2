// points_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import '../repositories/interfaces/point_transaction_repository.dart';
import '../models/point_transaction_model.dart';
import 'base_viewmodel.dart';

class PointsViewModel extends BaseViewModel {
  final IPointTransactionRepository _transactionRepository;

  List<PointTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentBalance = 0;

  List<PointTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentBalance => _currentBalance;

  // Public constructor for Provider
  PointsViewModel(Ref ref)
      : _transactionRepository = ref.watch(pointTransactionRepositoryProvider) {
    debugPrint('PointsViewModel: Public constructor called');
    _initialize();
  }

  // Internal constructor for dependency injection
  PointsViewModel._internal(Ref ref, this._transactionRepository) {
    debugPrint('PointsViewModel: Internal constructor called');
    _initialize();
  }

  void _initialize() {
    if (_transactionRepository.userId.isNotEmpty) {
      loadTransactions();
    } else {
      _setErrorState('Please sign in to view points');
    }
  }

  // FIXED: Define the _setErrorState method
  void _setErrorState(String message) {
    _errorMessage = message;
    _isLoading = false;
    _transactions = [];
    _currentBalance = 0;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    // Don't load if we're already in an error state for unauthenticated user
    if (_errorMessage?.contains('Please sign in') == true) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionRepository.getAll();
      _currentBalance = await _transactionRepository.getCurrentBalance();
      debugPrint('PointsViewModel: Loaded ${_transactions.length} transactions, balance: $_currentBalance');
    } catch (e) {
      _errorMessage = "Failed to load transactions: ${e.toString()}";
      debugPrint('PointsViewModel: Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> earnPoints({
    required int points,
    required String description,
    String? referenceId,
    String category = 'general',
  }) async {
    if (_transactionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to earn points');
      return;
    }

    try {
      await _transactionRepository.addEarnedPoints(
        points: points,
        description: description,
        referenceId: referenceId,
        category: category,
      );
      await loadTransactions(); // Reload
    } catch (e) {
      _errorMessage = "Failed to earn points: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> spendPoints({
    required int points,
    required String description,
    required String referenceId,
    String category = 'general',
  }) async {
    if (_transactionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to spend points');
      return;
    }

    try {
      await _transactionRepository.addSpentPoints(
        points: points,
        description: description,
        referenceId: referenceId,
        category: category,
      );
      await loadTransactions(); // Reload
    } catch (e) {
      _errorMessage = "Failed to spend points: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshTransactions() async {
    if (_transactionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to refresh transactions');
      return;
    }

    try {
      await _transactionRepository.syncWithRemote();
      await loadTransactions();
    } catch (e) {
      _errorMessage = "Failed to refresh transactions: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  Future<List<PointTransaction>> getRecentTransactions({int limit = 10}) async {
    if (_transactionRepository.userId.isEmpty) {
      return [];
    }

    return await _transactionRepository.getRecentTransactions(limit: limit);
  }

  // Clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}