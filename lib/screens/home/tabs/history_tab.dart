import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/call_provider.dart';
import 'package:beta_caller/models/call_model.dart';
import 'package:intl/intl.dart';
import 'package:beta_caller/screens/calling/calling_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedCallIds = {};
  bool _isSelectionMode = false;
  CallType? _filterType;
  String _searchQuery = '';
  Map<String, dynamic>? _statistics;
  bool _showStatistics = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    Future.microtask(() async {
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      await callProvider.loadCallHistory();
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final stats = await callProvider.getCallStatistics();
    setState(() {
      _statistics = stats;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedCallIds.clear();
      }
      if (_isSelectionMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleCallSelection(String callId) {
    setState(() {
      if (_selectedCallIds.contains(callId)) {
        _selectedCallIds.remove(callId);
      } else {
        _selectedCallIds.add(callId);
      }
    });
  }

  void _selectAll(List<CallModel> calls) {
    setState(() {
      _selectedCallIds.addAll(calls.map((c) => c.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedCallIds.clear();
    });
  }

  Future<void> _deleteSelectedCalls() async {
    if (_selectedCallIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calls'),
        content: Text(
          'Are you sure you want to delete ${_selectedCallIds.length} call(s) from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      await callProvider.deleteMultipleCallsFromHistory(_selectedCallIds.toList());
      await _loadStatistics();
      setState(() {
        _selectedCallIds.clear();
        _isSelectionMode = false;
        _animationController.reverse();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedCallIds.length} call(s) deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  List<CallModel> _getFilteredCalls(List<CallModel> calls) {
    var filtered = calls;

    // Filter by type
    if (_filterType != null) {
      filtered = filtered.where((call) => call.callType == _filterType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((call) {
        final query = _searchQuery.toLowerCase();
        return call.contactName.toLowerCase().contains(query) ||
               call.phoneNumber.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CallProvider>(
        builder: (context, callProvider, _) {
          final allCalls = callProvider.callHistory;
          final filteredCalls = _getFilteredCalls(allCalls);

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                elevation: 0,
                title: _isSelectionMode
                    ? Text('${_selectedCallIds.length} selected')
                    : const Text('Call History'),
                leading: _isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSelectionMode,
                      )
                    : null,
                actions: [
                  if (_isSelectionMode) ...[
                    if (_selectedCallIds.length != filteredCalls.length)
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () => _selectAll(filteredCalls),
                        tooltip: 'Select All',
                      ),
                    if (_selectedCallIds.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _deleteSelectedCalls,
                        tooltip: 'Delete Selected',
                      ),
                  ] else ...[
                    IconButton(
                      icon: Icon(
                        _showStatistics ? Icons.bar_chart : Icons.bar_chart_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _showStatistics = !_showStatistics;
                        });
                      },
                      tooltip: 'Statistics',
                    ),
                    if (allCalls.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'select') {
                            _toggleSelectionMode();
                          } else if (value == 'clear') {
                            _showClearHistoryDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.checklist),
                                SizedBox(width: 12),
                                Text('Select Calls'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Clear All', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),

              // Statistics Card (collapsible)
              if (_showStatistics && _statistics != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatisticsCard(),
                  ),
                ),

              // Search Bar
              if (!_isSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search calls...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),

              // Filter Chips
              if (!_isSelectionMode && allCalls.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _filterType == null,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.call_made,
                                  size: 16,
                                  color: _filterType == CallType.outgoing
                                      ? Colors.white
                                      : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                const Text('Outgoing'),
                              ],
                            ),
                            selected: _filterType == CallType.outgoing,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? CallType.outgoing : null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.call_received,
                                  size: 16,
                                  color: _filterType == CallType.incoming
                                      ? Colors.white
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                const Text('Incoming'),
                              ],
                            ),
                            selected: _filterType == CallType.incoming,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? CallType.incoming : null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.call_missed,
                                  size: 16,
                                  color: _filterType == CallType.missed
                                      ? Colors.white
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                const Text('Missed'),
                              ],
                            ),
                            selected: _filterType == CallType.missed,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? CallType.missed : null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Empty State
              if (filteredCalls.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.history,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No calls found'
                              : 'No call history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                // Call History List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final call = filteredCalls[index];
                      final isSelected = _selectedCallIds.contains(call.id);

                      return _buildCallHistoryCard(
                        call,
                        isSelected: isSelected,
                      );
                    },
                    childCount: filteredCalls.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalCalls = _statistics!['total_calls'] ?? 0;
    final totalDuration = _statistics!['total_duration'] ?? 0;
    final totalCost = (_statistics!['total_cost'] ?? 0.0) as double;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Call Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showStatistics = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Calls',
                  totalCalls.toString(),
                  Icons.phone,
                  Theme.of(context).primaryColor,
                ),
                _buildStatItem(
                  'Duration',
                  _formatDuration(totalDuration),
                  Icons.timer,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Cost',
                  '\$${totalCost.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  Widget _buildCallHistoryCard(CallModel call, {required bool isSelected}) {
    final callTypeColor = _getCallTypeColor(call.callType);
    final callTypeIcon = _getCallTypeIcon(call.callType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSelectionMode
              ? () => _toggleCallSelection(call.id)
              : null,
          onLongPress: !_isSelectionMode
              ? () {
                  _toggleSelectionMode();
                  _toggleCallSelection(call.id);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Selection Checkbox or Call Icon
                if (_isSelectionMode)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleCallSelection(call.id),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: callTypeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      callTypeIcon,
                      color: callTypeColor,
                      size: 24,
                    ),
                  ),

                const SizedBox(width: 12),

                // Call Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.contactName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        call.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(call.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (call.duration != null && call.duration! > 0) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Icon(
                              Icons.timer,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              call.formattedDuration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Cost and Call Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (call.cost != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          call.formattedCost,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_isSelectionMode)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.phone,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CallingScreen(
                                  phoneNumber: call.phoneNumber,
                                  contactName: call.contactName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCallTypeIcon(CallType type) {
    switch (type) {
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
    }
  }

  Color _getCallTypeColor(CallType type) {
    switch (type) {
      case CallType.outgoing:
        return Colors.green;
      case CallType.incoming:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all call history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final callProvider = Provider.of<CallProvider>(context, listen: false);
              await callProvider.clearCallHistory();
              await _loadStatistics();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Call history cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
