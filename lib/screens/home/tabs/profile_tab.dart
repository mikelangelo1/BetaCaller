import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/auth_provider.dart';
import 'package:beta_caller/providers/balance_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BalanceProvider>(context, listen: false).fetchBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer2<AuthProvider, BalanceProvider>(
        builder: (context, authProvider, balanceProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Profile header
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? user?.email ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (user?.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user!.phoneNumber!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Balance card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Balance',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: balanceProvider.isLoading
                                    ? null
                                    : () {
                                        balanceProvider.fetchBalance();
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            balanceProvider.formattedBalance,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddBalanceDialog(balanceProvider);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Balance'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Settings options
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {
                    // TODO: Navigate to edit profile screen
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.receipt_long,
                  title: 'Transaction History',
                  onTap: () {
                    // TODO: Navigate to transaction history screen
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    // TODO: Navigate to settings screen
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                const Divider(height: 32),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  onTap: () {
                    _handleLogout(authProvider);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAddBalanceDialog(BalanceProvider balanceProvider) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                hintText: '10.00',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select quick amount:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 20, 50, 100].map((amount) {
                return ChoiceChip(
                  label: Text('\$$amount'),
                  selected: false,
                  onSelected: (selected) {
                    if (selected) {
                      amountController.text = amount.toString();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.of(context).pop();
                final success = await balanceProvider.addBalance(amount);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Balance added successfully'
                            : 'Failed to add balance',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'BetaCaller',
        applicationVersion: '1.0.0',
        applicationIcon: Icon(
          Icons.phone_in_talk_rounded,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        children: const [
          Text('A VoIP calling app for low-cost international calls.'),
          SizedBox(height: 16),
          Text('Powered by Twilio'),
        ],
      ),
    );
  }

  void _handleLogout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
