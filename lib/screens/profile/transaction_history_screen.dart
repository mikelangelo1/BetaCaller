import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beta_caller/models/transaction_model.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final BetaCallerApiService _apiService = BetaCallerApiService();
  final ScrollController _scrollController = ScrollController();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  String? _filterType;
  String? _filterStatus;

  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadStatistics();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final result = await _apiService.getTransactionStatistics();
      if (result['success'] == true && mounted) {
        setState(() {
          _statistics = result;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _offset = 0;
        _transactions.clear();
        _hasMore = true;
      }
    });

    try {
      final result = await _apiService.getTransactionHistory(
        limit: _limit,
        offset: _offset,
        type: _filterType,
        status: _filterStatus,
      );

      if (result['success'] == true && mounted) {
        final List<dynamic> transactionsJson = result['transactions'] ?? [];
        final newTransactions = transactionsJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _hasMore = newTransactions.length >= _limit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    _offset += _limit;
    await _loadTransactions();
  }

  void _showFilterDialog() {
    String? tempType = _filterType;
    String? tempStatus = _filterStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: tempType == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        tempType = null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Credit'),
                    selected: tempType == 'credit',
                    onSelected: (selected) {
                      setDialogState(() {
                        tempType = selected ? 'credit' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Debit'),
                    selected: tempType == 'debit',
                    onSelected: (selected) {
                      setDialogState(() {
                        tempType = selected ? 'debit' : null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: tempStatus == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        tempStatus = null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: tempStatus == 'completed',
                    onSelected: (selected) {
                      setDialogState(() {
                        tempStatus = selected ? 'completed' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: tempStatus == 'pending',
                    onSelected: (selected) {
                      setDialogState(() {
                        tempStatus = selected ? 'pending' : null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = tempType;
                  _filterStatus = tempStatus;
                });
                Navigator.pop(context);
                _loadTransactions(refresh: true);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTransactions(refresh: true);
          await _loadStatistics();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Statistics Card
            if (_statistics != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Added',
                                '\$${_statistics!['totalAdded']?.toStringAsFixed(2) ?? '0.00'}',
                                Colors.green,
                                Icons.arrow_upward,
                              ),
                              _buildStatItem(
                                'Total Spent',
                                '\$${_statistics!['totalSpent']?.toStringAsFixed(2) ?? '0.00'}',
                                Colors.red,
                                Icons.arrow_downward,
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(
                            '${_statistics!['transactionCount'] ?? 0} Total Transactions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Filter Info
            if (_filterType != null || _filterStatus != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Chip(
                    label: Text(
                      'Filtered: ${_filterType != null ? _filterType!.toUpperCase() : ''} ${_filterStatus != null ? _filterStatus!.toUpperCase() : ''}'.trim(),
                    ),
                    onDeleted: () {
                      setState(() {
                        _filterType = null;
                        _filterStatus = null;
                      });
                      _loadTransactions(refresh: true);
                    },
                  ),
                ),
              ),

            // Transactions List
            if (_transactions.isEmpty && !_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _transactions.length) {
                        return _buildTransactionCard(_transactions[index]);
                      } else if (_hasMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount: _transactions.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          transaction.description ?? (isCredit ? 'Balance Added' : 'Call Charge'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (transaction.paymentMethod != null) ...[
              const SizedBox(height: 2),
              Text(
                'via ${transaction.paymentMethod!.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(transaction.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
