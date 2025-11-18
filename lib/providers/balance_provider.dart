import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beta_caller/services/api_service.dart';

class BalanceProvider with ChangeNotifier {
  double _balance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  List<Transaction> _transactions = [];

  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Transaction> get transactions => _transactions;

  final ApiService _apiService = ApiService();

  BalanceProvider() {
    _loadBalanceFromStorage();
  }

  Future<void> _loadBalanceFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _balance = prefs.getDouble('user_balance') ?? 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading balance from storage: $e');
    }
  }

  Future<void> fetchBalance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch balance from backend
      final response = await _apiService.getBalance();

      if (response['success'] == true) {
        _balance = response['balance']?.toDouble() ?? 0.0;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_balance', _balance);

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch balance';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBalance(double amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call backend to add balance
      final response = await _apiService.addBalance(amount);

      if (response['success'] == true) {
        _balance = response['new_balance']?.toDouble() ?? _balance;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_balance', _balance);

        await fetchTransactionHistory();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add balance';
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
        final List<dynamic> transactionData = response['transactions'] ?? [];
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
