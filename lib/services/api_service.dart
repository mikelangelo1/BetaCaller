import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'https://your-backend-api.com/api';

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Login failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      // For demo purposes, return mock data
      // Remove this in production
      return _mockLogin(email, password);
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Registration failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      // For demo purposes, return mock data
      return _mockRegister(email, phoneNumber);
    }
  }

  // Balance endpoints
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/balance'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch balance'};
      }
    } catch (e) {
      // Mock data for demo
      return {'success': true, 'balance': 25.50};
    }
  }

  Future<Map<String, dynamic>> addBalance(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/balance/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to add balance'};
      }
    } catch (e) {
      // Mock data for demo
      return {'success': true, 'new_balance': 25.50 + amount};
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch transactions'};
      }
    } catch (e) {
      // Mock data for demo
      return {
        'success': true,
        'transactions': [
          {
            'id': '1',
            'type': 'credit',
            'amount': 20.0,
            'description': 'Added balance',
            'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          },
          {
            'id': '2',
            'type': 'debit',
            'amount': 2.5,
            'description': 'Call to +1234567890',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ]
      };
    }
  }

  // Twilio token endpoint
  Future<Map<String, dynamic>> getTwilioToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/twilio/token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to get Twilio token'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting Twilio token: $e'
      };
    }
  }

  // Mock functions for demo (remove in production)
  Map<String, dynamic> _mockLogin(String email, String password) {
    return {
      'success': true,
      'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        'email': email,
        'phone_number': '+1234567890',
        'display_name': 'Demo User',
        'created_at': DateTime.now().toIso8601String(),
      }
    };
  }

  Map<String, dynamic> _mockRegister(String email, String phoneNumber) {
    return {
      'success': true,
      'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        'email': email,
        'phone_number': phoneNumber,
        'display_name': 'New User',
        'created_at': DateTime.now().toIso8601String(),
      }
    };
  }
}
