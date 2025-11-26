import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email';
  static const String _userTokenKey = 'user_token';

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      return canAuthenticate;
    } on PlatformException catch (e) {
      // Silently handle simulator/unsupported device errors
      if (e.code == 'channel-error') {
        // This is expected on simulators
        return false;
      }
      debugPrint('Error checking biometric availability: $e');
      return false;
    } catch (e) {
      // Handle any other errors silently
      return false;
    }
  }

  /// Get available biometric types (Face ID, Touch ID, Fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      // Silently handle simulator/unsupported device errors
      if (e.code == 'channel-error') {
        return [];
      }
      debugPrint('Error getting available biometrics: $e');
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'Biometric';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        debugPrint('Biometric authentication not available');
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometric({
    required String email,
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      // First authenticate to confirm user wants to enable biometrics
      final biometricName = await getBiometricTypeName();
      final bool authenticated = await authenticate(
        localizedReason: 'Authenticate to enable $biometricName login',
      );

      if (!authenticated) {
        return false;
      }

      // Store credentials securely
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(key: _userEmailKey, value: email);
      await _secureStorage.write(key: _userTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      }

      debugPrint('Biometric authentication enabled for: $email');
      return true;
    } catch (e) {
      debugPrint('Error enabling biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _userEmailKey);
      await _secureStorage.delete(key: _userTokenKey);
      await _secureStorage.delete(key: 'refresh_token');

      debugPrint('Biometric authentication disabled');
    } catch (e) {
      debugPrint('Error disabling biometric: $e');
    }
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error checking if biometric is enabled: $e');
      return false;
    }
  }

  /// Authenticate and retrieve stored credentials
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    try {
      final bool isEnabled = await isBiometricEnabled();

      if (!isEnabled) {
        debugPrint('Biometric authentication not enabled');
        return null;
      }

      final biometricName = await getBiometricTypeName();
      final bool authenticated = await authenticate(
        localizedReason: 'Authenticate with $biometricName to sign in',
      );

      if (!authenticated) {
        return null;
      }

      // Retrieve stored credentials
      final String? email = await _secureStorage.read(key: _userEmailKey);
      final String? accessToken = await _secureStorage.read(key: _userTokenKey);
      final String? refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (email == null || accessToken == null) {
        debugPrint('Stored credentials not found');
        return null;
      }

      return {
        'email': email,
        'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
      };
    } catch (e) {
      debugPrint('Error authenticating and getting credentials: $e');
      return null;
    }
  }

  /// Get stored user email (without authentication)
  Future<String?> getStoredEmail() async {
    try {
      return await _secureStorage.read(key: _userEmailKey);
    } catch (e) {
      debugPrint('Error getting stored email: $e');
      return null;
    }
  }

  /// Update stored session token
  Future<void> updateSessionToken(String sessionToken) async {
    try {
      final bool isEnabled = await isBiometricEnabled();

      if (isEnabled) {
        await _secureStorage.write(key: _userTokenKey, value: sessionToken);
        debugPrint('Session token updated in secure storage');
      }
    } catch (e) {
      debugPrint('Error updating session token: $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearAllData() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('All secure storage data cleared');
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }
}
