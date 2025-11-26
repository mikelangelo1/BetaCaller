import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';

class BalanceProvider with ChangeNotifier {
  double _balance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  List<Transaction> _transactions = [];

  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Transaction> get transactions => _transactions;

  final BetaCallerApiService _apiService = BetaCallerApiService();

  BalanceProvider() {
    // Don't await to prevent blocking app startup
    _loadBalanceFromStorage();
  }

  Future<void> _loadBalanceFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _balance = prefs.getDouble('user_balance') ?? 10.0; // Default 10.0
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading balance from storage: $e');
      _balance = 10.0; // Fallback to default
    }
  }

  Future<void> fetchBalance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch balance from backend using getUserProfile
      final response = await _apiService.getUserProfile();

      if (response['success'] == true) {
        _balance = response['balance']?.toDouble() ?? 10.0;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_balance', _balance);

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch balance';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBalance({
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call backend to add balance
      final response = await _apiService.addBalance(
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
      );

      if (response['success'] == true) {
        // The new API returns newBalance instead of balance
        _balance = response['newBalance']?.toDouble() ??
                   response['balance']?.toDouble() ??
                   _balance;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_balance', _balance);

        await fetchTransactionHistory();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to add balance';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deductBalance(double amount) async {
    if (_balance >= amount) {
      _balance -= amount;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_balance', _balance);

      notifyListeners();
    }
  }

  Future<void> fetchTransactionHistory() async {
    try {
      final response = await _apiService.getTransactionHistory();

      if (response['success'] == true) {
        final List<dynamic> transactionData = response['data'] ?? [];
        _transactions = transactionData
            .map((json) => Transaction.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching transaction history: $e');
    }
  }

  String get formattedBalance => '\$${_balance.toStringAsFixed(2)}';

  bool canMakeCall(double estimatedCost) {
    return _balance >= estimatedCost;
  }
}

class Transaction {
  final String id;
  final String type; // 'credit' or 'debit'
  final double amount;
  final String description;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'credit',
      amount: json['amount']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  String get formattedAmount {
    final sign = type == 'credit' ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }
}
