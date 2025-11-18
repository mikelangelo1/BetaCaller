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

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CallProvider>(context, listen: false).loadCallHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearHistoryDialog();
            },
          ),
        ],
      ),
      body: Consumer<CallProvider>(
        builder: (context, callProvider, _) {
          final callHistory = callProvider.callHistory;

          if (callHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No call history',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: callHistory.length,
            itemBuilder: (context, index) {
              final call = callHistory[index];
              return _buildCallHistoryTile(call);
            },
          );
        },
      ),
    );
  }

  Widget _buildCallHistoryTile(CallModel call) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCallTypeColor(call.callType),
        child: Icon(
          _getCallTypeIcon(call.callType),
          color: Colors.white,
        ),
      ),
      title: Text(call.contactName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(call.phoneNumber),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                DateFormat('MMM dd, HH:mm').format(call.timestamp),
                style: const TextStyle(fontSize: 12),
              ),
              if (call.duration != null && call.duration! > 0) ...[
                const Text(' • ', style: TextStyle(fontSize: 12)),
                Text(
                  call.formattedDuration,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.cost != null)
            Text(
              call.formattedCost,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
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
        ],
      ),
      onLongPress: () {
        _showDeleteCallDialog(call);
      },
    );
  }

  IconData _getCallTypeIcon(CallType type) {
    switch (type) {
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.incoming:
        return Icons.call_received;
      case CallType.missed:
        return Icons.call_missed;
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

  void _showDeleteCallDialog(CallModel call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call'),
        content: const Text('Are you sure you want to delete this call from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CallProvider>(context, listen: false)
                  .deleteCallFromHistory(call.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all call history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CallProvider>(context, listen: false).clearCallHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
