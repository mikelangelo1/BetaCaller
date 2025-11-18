import 'package:flutter/material.dart';
import 'package:beta_caller/screens/home/tabs/dialer_tab.dart';
import 'package:beta_caller/screens/home/tabs/contacts_tab.dart';
import 'package:beta_caller/screens/home/tabs/history_tab.dart';
import 'package:beta_caller/screens/home/tabs/profile_tab.dart';
import 'package:beta_caller/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _tabs = [
    const DialerTab(),
    const ContactsTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dialpad_rounded,
      activeIcon: Icons.dialpad,
      label: 'Dialer',
    ),
    _NavItem(
      icon: Icons.contacts_rounded,
      activeIcon: Icons.contacts,
      label: 'Contacts',
    ),
    _NavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history,
      label: 'History',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          _tabs[_currentIndex],
          // Glassmorphic gradient overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor).withOpacity(0),
                    (isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor).withOpacity(0.8),
                    (isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        constraints: const BoxConstraints(
          minHeight: 65,
          maxHeight: 75,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCardBackground,
                      AppTheme.darkCardBackground.withOpacity(0.95),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.98),
                    ],
                  ),
              border: Border.all(
                color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  return _buildNavItem(
                    _navItems[index],
                    index,
                    isDark,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index, bool isDark) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
            _animationController.forward(from: 0);
            _fabAnimationController.forward(from: 0);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with animated gradient background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated background glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isSelected ? 44 : 0,
                      height: isSelected ? 44 : 0,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                      ),
                    ),
                    // Icon
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: isSelected ? 24 : 20,
                        color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Label with scale animation
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: isSelected ? 10 : 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                      ? (isDark ? Colors.white : AppTheme.primaryColor)
                      : (isDark ? Colors.white60 : Colors.grey.shade500),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
