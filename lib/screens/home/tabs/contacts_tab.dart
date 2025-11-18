import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/contact_provider.dart';
import 'package:beta_caller/models/contact_model.dart';
import 'package:beta_caller/screens/calling/calling_screen.dart';
import 'package:beta_caller/utils/app_theme.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ContactProvider>(context, listen: false).loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar with modern design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contacts list
            Expanded(
              child: Consumer<ContactProvider>(
                builder: (context, contactProvider, _) {
                  if (contactProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Loading contacts...',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (contactProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                ? AppTheme.darkCardBackground
                                : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              contactProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => contactProvider.loadContacts(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final contacts = _searchQuery.isEmpty
                      ? contactProvider.contacts
                      : contactProvider.searchContacts(_searchQuery);

                  if (contacts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                ? AppTheme.darkCardBackground
                                : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.contacts_outlined,
                              size: 48,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isEmpty
                              ? 'No contacts found'
                              : 'No results for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                              ? 'Your contacts will appear here'
                              : 'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _buildContactTile(contact, contactProvider, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(ContactModel contact, ContactProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: contact.phoneNumber != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CallingScreen(
                        phoneNumber: contact.phoneNumber!,
                        contactName: contact.displayName,
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: contact.photoUrl != null
                        ? null
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: contact.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            contact.photoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            contact.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                // Contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phoneNumber ?? 'No phone number',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button
                    Container(
                      decoration: BoxDecoration(
                        color: contact.isFavorite
                            ? AppTheme.accentColor.withOpacity(0.1)
                            : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          contact.isFavorite ? Icons.star : Icons.star_border,
                          color: contact.isFavorite
                            ? AppTheme.accentColor
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                          size: 22,
                        ),
                        onPressed: () {
                          provider.toggleFavorite(contact.id);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Call button
                    Container(
                      decoration: BoxDecoration(
                        gradient: contact.phoneNumber != null
                            ? AppTheme.accentGradient
                            : null,
                        color: contact.phoneNumber == null
                            ? (isDark ? Colors.white12 : Colors.grey.shade200)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: contact.phoneNumber != null
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: contact.phoneNumber != null
                            ? Colors.white
                            : (isDark ? Colors.white24 : Colors.grey.shade400),
                          size: 22,
                        ),
                        onPressed: contact.phoneNumber != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CallingScreen(
                                      phoneNumber: contact.phoneNumber!,
                                      contactName: contact.displayName,
                                    ),
                                  ),
                                );
                              }
                            : null,
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
}
