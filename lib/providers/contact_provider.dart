import 'package:flutter/foundation.dart';
import 'package:beta_caller/models/contact_model.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactProvider with ChangeNotifier {
  List<ContactModel> _contacts = [];
  List<ContactModel> _favoriteContacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ContactModel> get contacts => _contacts;
  List<ContactModel> get favoriteContacts => _favoriteContacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Request permission
      final permissionStatus = await Permission.contacts.request();

      if (permissionStatus.isGranted) {
        // Load contacts from device
        // In a real implementation, you would use flutter_contacts package
        // For now, we'll use dummy data
        await Future.delayed(const Duration(seconds: 1));

        _contacts = _getDummyContacts();
        _favoriteContacts = _contacts.where((c) => c.isFavorite).toList();

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Contact permission denied';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error loading contacts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String contactId) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        isFavorite: !_contacts[index].isFavorite,
      );
      _favoriteContacts = _contacts.where((c) => c.isFavorite).toList();
      notifyListeners();
    }
  }

  List<ContactModel> searchContacts(String query) {
    if (query.isEmpty) return _contacts;

    return _contacts.where((contact) {
      final nameLower = contact.displayName.toLowerCase();
      final queryLower = query.toLowerCase();
      final phoneMatch = contact.phoneNumber?.contains(query) ?? false;

      return nameLower.contains(queryLower) || phoneMatch;
    }).toList();
  }

  ContactModel? getContactByPhoneNumber(String phoneNumber) {
    try {
      return _contacts.firstWhere(
        (contact) => contact.phoneNumber == phoneNumber,
      );
    } catch (e) {
      return null;
    }
  }

  // Dummy data for testing
  List<ContactModel> _getDummyContacts() {
    return [
      ContactModel(
        id: '1',
        displayName: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john@example.com',
        isFavorite: true,
      ),
      ContactModel(
        id: '2',
        displayName: 'Jane Smith',
        phoneNumber: '+1987654321',
        email: 'jane@example.com',
        isFavorite: false,
      ),
      ContactModel(
        id: '3',
        displayName: 'Bob Johnson',
        phoneNumber: '+1122334455',
        email: 'bob@example.com',
        isFavorite: true,
      ),
      ContactModel(
        id: '4',
        displayName: 'Alice Williams',
        phoneNumber: '+1555666777',
        email: 'alice@example.com',
        isFavorite: false,
      ),
      ContactModel(
        id: '5',
        displayName: 'Charlie Brown',
        phoneNumber: '+1999888777',
        email: 'charlie@example.com',
        isFavorite: false,
      ),
    ];
  }
}
