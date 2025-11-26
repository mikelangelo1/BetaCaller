import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClerkService {
  // Replace with your Clerk publishable key
  static const String _publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
  static const String _baseUrl = 'https://api.clerk.com/v1';

  String? _sessionToken;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _sessionToken != null && _user != null;
  Map<String, dynamic>? get currentUser => _user;
  String? get sessionToken => _sessionToken;

  /// Initialize Clerk service
  Future<void> initialize() async {
    try {
      debugPrint('Clerk service initialized');
    } catch (e) {
      debugPrint('Error initializing Clerk: $e');
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // In production, you would call Clerk's API
      // For now, we'll simulate a successful login

      // Example Clerk API call (commented out):
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/client/sign_ins'),
      //   headers: {
      //     'Authorization': 'Bearer $_publishableKey',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'identifier': email,
      //     'password': password,
      //   }),
      // );

      // Simulate successful login
      await Future.delayed(const Duration(seconds: 1));

      _sessionToken = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';
      _user = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'firstName': 'Demo',
        'lastName': 'User',
        'profileImageUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('Signed in successfully: ${_user!['email']}');

      return {
        'success': true,
        'user': _user,
        'sessionToken': _sessionToken,
      };
    } catch (e) {
      debugPrint('Error signing in: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // In production, you would call Clerk's sign-up API
      // Example:
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/client/sign_ups'),
      //   headers: {
      //     'Authorization': 'Bearer $_publishableKey',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'email_address': email,
      //     'password': password,
      //     'first_name': firstName,
      //     'last_name': lastName,
      //   }),
      // );

      // Simulate successful signup
      await Future.delayed(const Duration(seconds: 1));

      _sessionToken = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';
      _user = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'profileImageUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('Signed up successfully: ${_user!['email']}');

      return {
        'success': true,
        'user': _user,
        'sessionToken': _sessionToken,
      };
    } catch (e) {
      debugPrint('Error signing up: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign in with phone number (SMS OTP)
  Future<Map<String, dynamic>> signInWithPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      // In production, call Clerk's phone sign-in API
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'OTP sent to $phoneNumber',
        'requiresVerification': true,
      };
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify phone number with OTP
  Future<Map<String, dynamic>> verifyPhoneOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // In production, verify OTP with Clerk API
      await Future.delayed(const Duration(seconds: 1));

      _sessionToken = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';
      _user = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'phoneNumber': phoneNumber,
        'firstName': 'Phone',
        'lastName': 'User',
        'profileImageUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      return {
        'success': true,
        'user': _user,
        'sessionToken': _sessionToken,
      };
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_sessionToken == null) return null;

    try {
      // In production, fetch user from Clerk API
      // final response = await http.get(
      //   Uri.parse('$_baseUrl/users/me'),
      //   headers: {
      //     'Authorization': 'Bearer $_sessionToken',
      //   },
      // );

      return _user;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      if (_user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // In production, update via Clerk API
      await Future.delayed(const Duration(milliseconds: 500));

      if (firstName != null) _user!['firstName'] = firstName;
      if (lastName != null) _user!['lastName'] = lastName;
      if (phoneNumber != null) _user!['phoneNumber'] = phoneNumber;

      return {
        'success': true,
        'user': _user,
      };
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // In production, invalidate session with Clerk API
      // await http.post(
      //   Uri.parse('$_baseUrl/client/sessions/$_sessionToken/end'),
      //   headers: {
      //     'Authorization': 'Bearer $_publishableKey',
      //   },
      // );

      _sessionToken = null;
      _user = null;

      debugPrint('Signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Check if session is valid
  Future<bool> validateSession() async {
    if (_sessionToken == null) return false;

    try {
      // In production, validate session with Clerk API
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return false;
    }
  }

  /// Refresh session token
  Future<String?> refreshSession() async {
    try {
      // In production, refresh session with Clerk API
      await Future.delayed(const Duration(milliseconds: 500));
      _sessionToken = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';
      return _sessionToken;
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      return null;
    }
  }
}
