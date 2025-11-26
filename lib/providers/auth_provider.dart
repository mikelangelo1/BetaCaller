import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beta_caller/models/user_model.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';
import 'package:beta_caller/services/biometric_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';

  UserModel? get user => _user;
  String? get token => _accessToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get biometricEnabled => _biometricEnabled;
  String get biometricType => _biometricType;

  final BetaCallerApiService _apiService = BetaCallerApiService();
  final BiometricService _biometricService = BiometricService();

  AuthProvider() {
    // Don't await initialization - let it run in background
    // This prevents blocking app startup
    _initialize();
  }

  Future<void> _initialize() async {
    // Run initialization without blocking
    _checkBiometricAvailability();
    _loadUserFromStorage();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (isAvailable) {
        _biometricType = await _biometricService.getBiometricTypeName();
        _biometricEnabled = await _biometricService.isBiometricEnabled();
        notifyListeners();
      }
    } catch (e) {
      // Biometric not available (simulator or unsupported device)
      debugPrint('Biometric not available: $e');
      _biometricEnabled = false;
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      final userFirstName = prefs.getString('user_first_name');
      final userLastName = prefs.getString('user_last_name');

      if (_accessToken != null && userId != null && userEmail != null) {
        // Set tokens in API service
        _apiService.setTokens(_accessToken!, _refreshToken ?? '');

        // Try to validate session by fetching user profile
        // Wrap in try-catch to prevent app crash on network errors
        try {
          final response = await _apiService.getProfile().timeout(
            const Duration(seconds: 5),
            onTimeout: () => {'success': false, 'error': 'Connection timeout'},
          );

          if (response['success'] == true) {
            _user = UserModel.fromJson(response);
            notifyListeners();
          } else {
            // Token might be expired, try to refresh
            if (_refreshToken != null) {
              final refreshResult = await _apiService.refreshAccessToken().timeout(
                const Duration(seconds: 5),
                onTimeout: () => {'success': false, 'error': 'Connection timeout'},
              );
              if (refreshResult['success'] == true) {
                _accessToken = _apiService.accessToken;
                _refreshToken = _apiService.refreshToken;
                await _saveToStorage();

                // Retry getting profile
                final retryResponse = await _apiService.getProfile().timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => {'success': false, 'error': 'Connection timeout'},
                );
                if (retryResponse['success'] == true) {
                  _user = UserModel.fromJson(retryResponse);
                  notifyListeners();
                  return;
                }
              }
            }

            // If all fails, clear storage
            await _clearStorage();
          }
        } catch (networkError) {
          debugPrint('Network error during session validation: $networkError');
          // Don't clear storage on network errors, just proceed without validation
          // User can try logging in again if needed
        }
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
      // Don't clear storage, just log the error
      // This prevents crashes due to network issues during app startup
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _accessToken = response['accessToken'];
        _refreshToken = response['refreshToken'];
        _user = UserModel.fromJson(response['user']);

        _apiService.setTokens(_accessToken!, _refreshToken!);
        await _saveToStorage();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (response['success'] == true) {
        _accessToken = response['accessToken'];
        _refreshToken = response['refreshToken'];
        _user = UserModel.fromJson(response['user']);

        _apiService.setTokens(_accessToken!, _refreshToken!);
        await _saveToStorage();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with phone number (OTP) - Not implemented yet in backend
  Future<bool> loginWithPhone(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // TODO: Implement phone auth in backend
    _errorMessage = 'Phone authentication not yet implemented';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Verify phone OTP - Not implemented yet in backend
  Future<bool> verifyPhoneOTP(String phoneNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // TODO: Implement phone auth in backend
    _errorMessage = 'Phone authentication not yet implemented';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credentials = await _biometricService.authenticateAndGetCredentials();

      if (credentials == null) {
        _errorMessage = 'Biometric authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use stored tokens
      _accessToken = credentials['accessToken'];
      _refreshToken = credentials['refreshToken'];

      // Set tokens in API service
      _apiService.setTokens(_accessToken!, _refreshToken ?? '');

      // Validate session by fetching profile
      final response = await _apiService.getProfile();

      if (response['success'] == true) {
        _user = UserModel.fromJson(response);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Try to refresh token
        if (_refreshToken != null) {
          final refreshResult = await _apiService.refreshAccessToken();
          if (refreshResult['success'] == true) {
            _accessToken = _apiService.accessToken;
            _refreshToken = _apiService.refreshToken;
            await _saveToStorage();

            // Retry
            final retryResponse = await _apiService.getProfile();
            if (retryResponse['success'] == true) {
              _user = UserModel.fromJson(retryResponse);
              _isLoading = false;
              notifyListeners();
              return true;
            }
          }
        }

        // Session expired, need to re-login
        await disableBiometric();
        _errorMessage = 'Session expired. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Biometric authentication error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    if (_user == null || _accessToken == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      final success = await _biometricService.enableBiometric(
        email: _user!.email,
        accessToken: _accessToken!,
        refreshToken: _refreshToken,
      );

      if (success) {
        _biometricEnabled = true;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error enabling biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
    _biometricEnabled = false;
    notifyListeners();
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  /// Get stored email for biometric login
  Future<String?> getStoredBiometricEmail() async {
    return await _biometricService.getStoredEmail();
  }

  /// Logout
  Future<void> logout() async {
    await _apiService.logout();
    await _clearStorage();

    _user = null;
    _accessToken = null;
    _refreshToken = null;

    notifyListeners();
  }

  /// Save user data to storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _accessToken!);
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
    await prefs.setString('user_id', _user!.id);
    await prefs.setString('user_email', _user!.email);
    await prefs.setString('user_first_name', _user!.firstName);
    await prefs.setString('user_last_name', _user!.lastName);
    if (_user!.phoneNumber != null) {
      await prefs.setString('user_phone', _user!.phoneNumber!);
    }
    await prefs.setDouble('user_balance', _user!.balance);
  }

  /// Clear storage
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_balance');
    _apiService.clearTokens();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? displayName,
  }) async {
    if (_user == null) return false;

    try {
      final response = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        displayName: displayName,
      );

      if (response['success'] == true) {
        _user = UserModel.fromJson(response);
        await _saveToStorage();
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }
}
