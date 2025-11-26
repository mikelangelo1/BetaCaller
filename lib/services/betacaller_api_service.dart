import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BetaCallerApiService {
  // Backend API base URL
  // For local development: use your machine's IP address or localhost
  // For iOS simulator: http://localhost:3000
  // For Android emulator: http://10.0.2.2:3000
  // For physical device: http://YOUR_IP:3000
  static const String baseUrl = kDebugMode
      ? 'http://10.203.37.8:3000/api'  // Your Mac's IP address for physical devices/simulators
      : 'https://your-production-api.com/api';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  /// Set authentication tokens
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Get authorization headers
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Handle API errors
  Map<String, dynamic> _handleError(dynamic error, {String? defaultMessage}) {
    debugPrint('API Error: $error');
    return {
      'success': false,
      'error': defaultMessage ?? 'Network error: $error',
    };
  }

  /// Parse response body
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...body};
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Request failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );

      final result = _parseResponse(response);

      if (result['success'] == true && result['accessToken'] != null) {
        _accessToken = result['accessToken'];
        _refreshToken = result['refreshToken'];
      }

      return result;
    } catch (e) {
      return _handleError(e, defaultMessage: 'Registration failed');
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = _parseResponse(response);

      if (result['success'] == true && result['accessToken'] != null) {
        _accessToken = result['accessToken'];
        _refreshToken = result['refreshToken'];
      }

      return result;
    } catch (e) {
      return _handleError(e, defaultMessage: 'Login failed');
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    if (_refreshToken == null) {
      return {'success': false, 'error': 'No refresh token available'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _getHeaders(),
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      );

      final result = _parseResponse(response);

      if (result['success'] == true && result['accessToken'] != null) {
        _accessToken = result['accessToken'];
        _refreshToken = result['refreshToken'];
      }

      return result;
    } catch (e) {
      return _handleError(e, defaultMessage: 'Token refresh failed');
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch profile');
    }
  }

  /// Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getHeaders(includeAuth: true),
      );

      clearTokens();
      return _parseResponse(response);
    } catch (e) {
      clearTokens();
      return _handleError(e, defaultMessage: 'Logout failed');
    }
  }

  // ==================== USER ENDPOINTS ====================

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch user profile');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? displayName,
    String? profileImageUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (displayName != null) body['displayName'] = displayName;
      if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to update profile');
    }
  }

  // ==================== BALANCE ENDPOINTS ====================

  /// Get user balance
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: _getHeaders(includeAuth: true),
      );

      final result = _parseResponse(response);

      if (result['success'] == true) {
        return {
          'success': true,
          'balance': result['balance'] ?? 0.0,
        };
      }

      return result;
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch balance');
    }
  }

  // ==================== TWILIO ENDPOINTS ====================

  /// Get Twilio access token for voice calls
  Future<Map<String, dynamic>> getTwilioToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/twilio/token'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to get Twilio token');
    }
  }

  // ==================== CALL ENDPOINTS (Multi-Provider VoIP) ====================

  /// Get VoIP token (supports Voximplant, Twilio, Telnyx with automatic failover)
  Future<Map<String, dynamic>> getVoipToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calls/token'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to get VoIP token');
    }
  }

  /// Legacy: Get Telnyx WebRTC token (deprecated, use getVoipToken instead)
  @Deprecated('Use getVoipToken instead for multi-provider support')
  Future<Map<String, dynamic>> getTelnyxToken() async {
    return getVoipToken();
  }

  /// Initiate a call
  Future<Map<String, dynamic>> initiateCall({
    required String to,
    String? from,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calls/initiate'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'to': to,
          if (from != null) 'from': from,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to initiate call');
    }
  }

  /// Get call rate for a destination
  Future<Map<String, dynamic>> getCallRate(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calls/rate/${Uri.encodeComponent(phoneNumber)}'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to get call rate');
    }
  }

  /// Estimate call cost
  Future<Map<String, dynamic>> estimateCallCost(
    String phoneNumber, {
    double minutes = 1.0,
  }) async {
    try {
      final queryParams = {
        'phoneNumber': phoneNumber,
        'minutes': minutes.toString(),
      };

      final uri = Uri.parse('$baseUrl/calls/estimate-cost')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to estimate cost');
    }
  }

  /// Create a call record (legacy - for backwards compatibility)
  Future<Map<String, dynamic>> createCallRecord({
    required String toNumber,
    String? fromNumber,
  }) async {
    return await initiateCall(to: toNumber, from: fromNumber);
  }

  /// Update call record
  Future<Map<String, dynamic>> updateCallRecord({
    required String callId,
    String? status,
    int? duration,
    double? cost,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (duration != null) body['duration'] = duration;
      if (cost != null) body['cost'] = cost;

      final response = await http.put(
        Uri.parse('$baseUrl/calls/$callId'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to update call record');
    }
  }

  /// Get call history
  Future<Map<String, dynamic>> getCallHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calls?limit=$limit&offset=$offset'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch call history');
    }
  }

  // ==================== TRANSACTION ENDPOINTS ====================

  /// Get transaction history
  Future<Map<String, dynamic>> getTransactionHistory({
    int limit = 20,
    int offset = 0,
    String? type,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch transactions');
    }
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/statistics'),
        headers: _getHeaders(includeAuth: true),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to fetch statistics');
    }
  }

  /// Add balance (top-up)
  Future<Map<String, dynamic>> addBalance({
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/add-balance'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'amount': amount,
          'paymentMethod': paymentMethod,
          if (reference != null) 'reference': reference,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to add balance');
    }
  }

  // ==================== PAYMENT ENDPOINTS ====================

  /// Get current exchange rate (NGN to USD)
  Future<Map<String, dynamic>> getExchangeRate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/exchange-rate'),
        headers: _getHeaders(),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to get exchange rate');
    }
  }

  /// Create Stripe Payment Intent
  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/stripe/create-payment-intent'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'email': email,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to create payment intent');
    }
  }

  /// Verify Paystack Payment
  Future<Map<String, dynamic>> verifyPaystackPayment(String reference) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/paystack/verify'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'reference': reference,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to verify payment');
    }
  }

  /// Verify Stripe Payment
  Future<Map<String, dynamic>> verifyStripePayment(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/stripe/verify'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to verify payment');
    }
  }

  /// Initialize Paystack Payment
  Future<Map<String, dynamic>> initializePaystackPayment({
    required int amount,
    required String email,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/paystack/initialize'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'amount': amount,
          'email': email,
          'reference': reference,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return _handleError(e, defaultMessage: 'Failed to initialize payment');
    }
  }
}
