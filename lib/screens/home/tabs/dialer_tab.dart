import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/call_provider.dart';
import 'package:beta_caller/providers/balance_provider.dart';
import 'package:beta_caller/screens/calling/calling_screen.dart';
import 'package:beta_caller/screens/balance/add_balance_screen.dart';
import 'package:beta_caller/utils/app_theme.dart';
import 'package:beta_caller/widgets/call_rate_display.dart';

class DialerTab extends StatefulWidget {
  const DialerTab({super.key});

  @override
  State<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends State<DialerTab> with SingleTickerProviderStateMixin {
  String _phoneNumber = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    setState(() {
      _phoneNumber += digit;
    });
  }

  void _deleteDigit() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _clearNumber() {
    setState(() {
      _phoneNumber = '';
    });
  }

  bool _validatePhoneNumber(String number) {
    // Remove spaces and special characters except +
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    // Must be at least 7 digits
    if (cleaned.length < 7) return false;

    // Must not exceed 15 digits (international standard)
    if (cleaned.length > 15) return false;

    // If starts with +, must have country code (1-3 digits)
    if (cleaned.startsWith('+')) {
      if (cleaned.length < 10) return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _makeCall() async {
    if (_phoneNumber.isEmpty) {
      _showValidationError('Please enter a phone number');
      return;
    }

    // Validate phone number
    if (!_validatePhoneNumber(_phoneNumber)) {
      _showValidationError('Please enter a valid phone number (7-15 digits)');
      return;
    }

    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);

    // Check if user has sufficient balance
    if (!balanceProvider.canMakeCall(0.10)) {
      if (!mounted) return;
      _showValidationError('Insufficient balance. Please add credit.');
      return;
    }

    // Navigate to calling screen
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallingScreen(
          phoneNumber: _phoneNumber,
          contactName: _phoneNumber,
        ),
      ),
    );
  }

  void _showAddBalanceDialog(BuildContext context, BalanceProvider balanceProvider) {
    // Navigate to Add Balance Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddBalanceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;

            // Responsive sizing
            final isSmallScreen = availableHeight < 700;
            final isVerySmallScreen = availableHeight < 650;

            return Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isVerySmallScreen ? 8 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BetaCaller',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          foreground: Paint()
                            ..shader = AppTheme.primaryGradient.createShader(
                              const Rect.fromLTWH(0, 0, 200, 70),
                            ),
                        ),
                      ),
                      Consumer<BalanceProvider>(
                        builder: (context, balanceProvider, _) {
                          return GestureDetector(
                            onTap: () {
                              _showAddBalanceDialog(context, balanceProvider);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 12 : 16,
                                vertical: isVerySmallScreen ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: isVerySmallScreen ? 16 : 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: isVerySmallScreen ? 6 : 8),
                                  Text(
                                    balanceProvider.formattedBalance,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isVerySmallScreen ? 13 : 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Phone number display
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isVerySmallScreen ? 8 : 12,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _buildQuickActions(isDark),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: isVerySmallScreen ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _phoneNumber.isEmpty
                              ? Colors.transparent
                              : AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _phoneNumber.isEmpty ? 'Enter number' : _phoneNumber,
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: _phoneNumber.isEmpty
                                    ? Colors.grey.shade400
                                    : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_phoneNumber.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.backspace_outlined,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                                size: 20,
                              ),
                              onPressed: _deleteDigit,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Call rate display
                if (_phoneNumber.isNotEmpty && _phoneNumber.length >= 8)
                  CallRateDisplay(phoneNumber: _phoneNumber),

                // Dial pad - takes remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final padHeight = constraints.maxHeight;
                        final buttonSize = (availableWidth - 80) / 3;
                        final maxButtonHeight = (padHeight - 60) / 4; // 4 rows with spacing
                        final actualButtonSize = buttonSize < maxButtonHeight ? buttonSize : maxButtonHeight;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDialRow(['1', '2', '3'], ['', 'ABC', 'DEF'], isDark, actualButtonSize, isVerySmallScreen),
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            _buildDialRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO'], isDark, actualButtonSize, isVerySmallScreen),
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            _buildDialRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ'], isDark, actualButtonSize, isVerySmallScreen),
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            _buildDialRow(['*', '0', '#'], ['', '+', ''], isDark, actualButtonSize, isVerySmallScreen),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Call button
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isVerySmallScreen ? 8 : 16,
                    top: isVerySmallScreen ? 8 : 12,
                  ),
                  child: Container(
                    width: isVerySmallScreen ? 60 : (isSmallScreen ? 64 : 72),
                    height: isVerySmallScreen ? 60 : (isSmallScreen ? 64 : 72),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _phoneNumber.isEmpty
                          ? LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade500],
                            )
                          : AppTheme.accentGradient,
                      boxShadow: _phoneNumber.isEmpty
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _phoneNumber.isEmpty ? null : _makeCall,
                        borderRadius: BorderRadius.circular(36),
                        child: Center(
                          child: Icon(
                            Icons.phone,
                            size: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialRow(List<String> digits, List<String> letters, bool isDark, double size, bool isVerySmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 4 : 6),
          child: SizedBox(
            width: size,
            height: size,
            child: _buildDialButton(digits[index], letters[index], isDark, isVerySmall),
          ),
        );
      }),
    );
  }

  Widget _buildDialButton(String digit, String letters, bool isDark, bool isVerySmall) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addDigit(digit),
        borderRadius: BorderRadius.circular(60),
        splashColor: AppTheme.primaryColor.withOpacity(0.2),
        highlightColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: isVerySmall ? 22 : 28,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              if (letters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    letters,
                    style: TextStyle(
                      fontSize: isVerySmall ? 8 : 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          _buildQuickActionItem(
            icon: Icons.paste,
            title: 'Paste from clipboard',
            subtitle: 'Paste a phone number',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.contacts,
            title: 'Choose from contacts',
            subtitle: 'Select a contact to call',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.history,
            title: 'Recent calls',
            subtitle: 'View call history',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
