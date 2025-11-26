import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/auth_provider.dart';
import 'package:beta_caller/providers/balance_provider.dart';
import 'package:beta_caller/screens/profile/edit_profile_screen.dart';
import 'package:beta_caller/screens/profile/transaction_history_screen.dart';
import 'package:beta_caller/screens/profile/settings_screen.dart';
import 'package:beta_caller/screens/profile/help_support_screen.dart';
import 'package:beta_caller/screens/balance/add_balance_screen.dart';

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
      body: Consumer2<AuthProvider, BalanceProvider>(
        builder: (context, authProvider, balanceProvider, _) {
          final user = authProvider.user;

          return CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Profile Picture
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: user?.profileImageUrl != null
                                  ? NetworkImage(user!.profileImageUrl!)
                                  : null,
                              child: user?.profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            user?.displayName ?? '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Email
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Body content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Balance Card with improved design
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.8),
                              Theme.of(context).primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Current Balance',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.white),
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
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showAddBalanceDialog(balanceProvider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text(
                                    'Add Balance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildSectionHeader('Account'),
                    _buildModernTile(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernTile(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Transaction History',
                      subtitle: 'View your payment history',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // App Settings Section
                    _buildSectionHeader('App Settings'),
                    _buildModernTile(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences and notifications',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernTile(
                      context: context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help or contact support',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernTile(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),

                    const SizedBox(height: 16),

                    // Logout Section
                    _buildModernTile(
                      context: context,
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        _handleLogout(authProvider);
                      },
                    ),

                    // Extra padding to clear bottom navigation bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showAddBalanceDialog(BalanceProvider balanceProvider) {
    // Navigate to the full AddBalanceScreen with payment gateway integration
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBalanceScreen(),
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
