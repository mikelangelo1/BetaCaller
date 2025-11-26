import 'package:flutter/foundation.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';
import 'package:beta_caller/utils/nigerian_phone_util.dart';

/// Supported VoIP providers
enum VoipProvider {
  voximplant,
  twilio,
  telnyx,
}

/// Call states
enum VoipCallState {
  idle,
  connecting,
  ringing,
  active,
  held,
  ended,
  failed,
}

/// Provider configuration from backend
class VoipProviderConfig {
  final VoipProvider provider;
  final String? accountName;
  final String? applicationName;
  final String? identity;
  final String? appId;

  VoipProviderConfig({
    required this.provider,
    this.accountName,
    this.applicationName,
    this.identity,
    this.appId,
  });

  factory VoipProviderConfig.fromJson(Map<String, dynamic> json, String providerName) {
    return VoipProviderConfig(
      provider: _parseProvider(providerName),
      accountName: json['accountName'],
      applicationName: json['applicationName'],
      identity: json['identity'],
      appId: json['appId'],
    );
  }

  static VoipProvider _parseProvider(String name) {
    switch (name.toLowerCase()) {
      case 'voximplant':
        return VoipProvider.voximplant;
      case 'twilio':
        return VoipProvider.twilio;
      case 'telnyx':
        return VoipProvider.telnyx;
      default:
        return VoipProvider.voximplant;
    }
  }
}

/// Call rate information
class CallRateInfo {
  final double ratePerMinute;
  final double connectionFee;
  final double estimatedCost;
  final String countryCode;
  final String countryName;
  final String? carrierName;
  final String? networkType;

  CallRateInfo({
    required this.ratePerMinute,
    required this.connectionFee,
    required this.estimatedCost,
    required this.countryCode,
    required this.countryName,
    this.carrierName,
    this.networkType,
  });

  factory CallRateInfo.fromJson(Map<String, dynamic> json) {
    return CallRateInfo(
      ratePerMinute: (json['ratePerMinute'] as num).toDouble(),
      connectionFee: (json['connectionFee'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      carrierName: json['carrierName'] as String?,
      networkType: json['networkType'] as String?,
    );
  }

  String get formattedRate => '\$${ratePerMinute.toStringAsFixed(4)}/min';
  String get formattedEstimate => '\$${estimatedCost.toStringAsFixed(4)}';
}

/// Active call information
class ActiveCall {
  final String callId;
  final String to;
  final String from;
  final CallRateInfo rate;
  final VoipProvider provider;
  VoipCallState state;
  DateTime? connectedAt;
  int durationSeconds;

  ActiveCall({
    required this.callId,
    required this.to,
    required this.from,
    required this.rate,
    required this.provider,
    this.state = VoipCallState.connecting,
    this.connectedAt,
    this.durationSeconds = 0,
  });

  double get estimatedCost {
    if (durationSeconds == 0) return rate.estimatedCost;

    final minutes = durationSeconds / 60;
    return (minutes * rate.ratePerMinute) + rate.connectionFee;
  }

  String get formattedCost => '\$${estimatedCost.toStringAsFixed(4)}';

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get providerName {
    switch (provider) {
      case VoipProvider.voximplant:
        return 'Voximplant';
      case VoipProvider.twilio:
        return 'Twilio';
      case VoipProvider.telnyx:
        return 'Telnyx';
    }
  }
}

/// Multi-provider VoIP call service
/// Supports Voximplant, Twilio, and Telnyx with automatic failover
class VoipCallService extends ChangeNotifier {
  final BetaCallerApiService _apiService = BetaCallerApiService();

  ActiveCall? _activeCall;
  String? _token;
  DateTime? _tokenExpiresAt;
  VoipProvider? _currentProvider;
  VoipProviderConfig? _providerConfig;

  ActiveCall? get activeCall => _activeCall;
  bool get hasActiveCall => _activeCall != null;
  VoipCallState get callState => _activeCall?.state ?? VoipCallState.idle;
  VoipProvider? get currentProvider => _currentProvider;

  /// Get or refresh authentication token from backend
  /// Backend handles provider selection and failover
  Future<String> _getToken() async {
    // Check if we have a valid token
    if (_token != null && _tokenExpiresAt != null) {
      if (DateTime.now().isBefore(_tokenExpiresAt!)) {
        return _token!;
      }
    }

    // Get new token from backend
    debugPrint('Getting VoIP token from backend...');
    final response = await _apiService.getVoipToken();

    if (response['success'] == true) {
      _token = response['token'] as String;
      final expiresIn = response['expiresIn'] as int? ?? 86400;
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // Parse provider info
      final providerName = response['provider'] as String? ?? 'voximplant';
      _currentProvider = VoipProviderConfig._parseProvider(providerName);

      if (response['providerConfig'] != null) {
        _providerConfig = VoipProviderConfig.fromJson(
          response['providerConfig'] as Map<String, dynamic>,
          providerName,
        );
      }

      debugPrint('Token obtained for provider: $_currentProvider, expires at: $_tokenExpiresAt');
      return _token!;
    } else {
      throw Exception('Failed to get VoIP token: ${response['error']}');
    }
  }

  /// Get call rate for a destination
  Future<CallRateInfo> getCallRate(String phoneNumber) async {
    final formattedNumber = NigerianPhoneUtil.formatToE164(phoneNumber);
    debugPrint('Getting rate for: $formattedNumber');

    final response = await _apiService.getCallRate(formattedNumber);

    if (response['success'] == true) {
      return CallRateInfo.fromJson(response);
    } else {
      throw Exception('Failed to get call rate: ${response['error']}');
    }
  }

  /// Estimate call cost
  Future<Map<String, dynamic>> estimateCallCost(
    String phoneNumber, {
    double minutes = 1.0,
  }) async {
    final formattedNumber = NigerianPhoneUtil.formatToE164(phoneNumber);

    final response = await _apiService.estimateCallCost(
      formattedNumber,
      minutes: minutes,
    );

    if (response['success'] == true) {
      return {
        'rate': CallRateInfo.fromJson(response['rate']),
        'estimatedCost': (response['estimatedCost'] as num).toDouble(),
        'billedSeconds': response['billedSeconds'] as int,
      };
    } else {
      throw Exception('Failed to estimate cost: ${response['error']}');
    }
  }

  /// Initiate a call
  /// Backend will use the best available provider with failover
  Future<void> initiateCall({
    required String to,
    String? contactName,
  }) async {
    if (_activeCall != null) {
      throw Exception('Another call is already active');
    }

    try {
      // Format phone number
      final formattedNumber = NigerianPhoneUtil.formatToE164(to);
      debugPrint('Initiating call to: $formattedNumber');

      // Get call rate
      final rate = await getCallRate(formattedNumber);
      debugPrint('Call rate: ${rate.formattedRate}');

      // Initiate call through backend
      final response = await _apiService.initiateCall(to: formattedNumber);

      if (response['success'] == true) {
        // Get token (this also gets the provider info)
        await _getToken();

        // Create active call object
        _activeCall = ActiveCall(
          callId: response['callId'] as String,
          to: formattedNumber,
          from: 'client',
          rate: rate,
          provider: _currentProvider ?? VoipProvider.voximplant,
          state: VoipCallState.connecting,
        );

        notifyListeners();

        // In a real implementation, you would:
        // 1. Initialize the appropriate SDK based on provider
        // 2. For Voximplant: use VIClient
        // 3. For Twilio: use TwilioVoice
        // 4. For Telnyx: use TelnyxClient
        // For now, we'll simulate the call flow

        // Simulate ringing
        await Future.delayed(const Duration(seconds: 2));
        _updateCallState(VoipCallState.ringing);

        // Simulate answer (in real app, this comes from SDK events)
        await Future.delayed(const Duration(seconds: 3));
        _updateCallState(VoipCallState.active);
        _activeCall!.connectedAt = DateTime.now();

        // Start call timer
        _startCallTimer();
      } else {
        throw Exception('Failed to initiate call: ${response['error']}');
      }
    } catch (e) {
      _activeCall = null;
      notifyListeners();
      rethrow;
    }
  }

  /// End the active call
  Future<void> endCall() async {
    if (_activeCall == null) {
      debugPrint('No active call to end');
      return;
    }

    try {
      debugPrint('Ending call: ${_activeCall!.callId}');

      // Update state
      _updateCallState(VoipCallState.ended);

      // In a real implementation, end call via the appropriate SDK

      // Clean up
      _activeCall = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending call: $e');
      _activeCall = null;
      notifyListeners();
    }
  }

  /// Put call on hold
  Future<void> holdCall() async {
    if (_activeCall == null || _activeCall!.state != VoipCallState.active) {
      return;
    }

    _updateCallState(VoipCallState.held);
  }

  /// Resume call from hold
  Future<void> resumeCall() async {
    if (_activeCall == null || _activeCall!.state != VoipCallState.held) {
      return;
    }

    _updateCallState(VoipCallState.active);
  }

  /// Mute/unmute call
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('Mute toggled: $_isMuted');
    notifyListeners();
  }

  /// Speaker on/off
  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    debugPrint('Speaker toggled: $_isSpeakerOn');
    notifyListeners();
  }

  /// Send DTMF tones
  void sendDTMF(String digit) {
    if (_activeCall == null || _activeCall!.state != VoipCallState.active) {
      return;
    }

    debugPrint('Sending DTMF: $digit');
  }

  /// Private: Update call state
  void _updateCallState(VoipCallState newState) {
    if (_activeCall == null) return;

    _activeCall!.state = newState;
    debugPrint('Call state changed: $newState');
    notifyListeners();
  }

  /// Private: Start call duration timer
  void _startCallTimer() {
    if (_activeCall == null) return;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (_activeCall == null ||
          _activeCall!.state == VoipCallState.ended ||
          _activeCall!.state == VoipCallState.failed) {
        return false; // Stop timer
      }

      if (_activeCall!.state == VoipCallState.active) {
        _activeCall!.durationSeconds++;
        notifyListeners();
      }

      return true; // Continue timer
    });
  }

  /// Get Nigerian-specific info for a number
  Map<String, dynamic> getNigerianInfo(String phoneNumber) {
    final carrier = NigerianPhoneUtil.detectCarrier(phoneNumber);
    final networkType = NigerianPhoneUtil.getNetworkType(phoneNumber);
    final formatted = NigerianPhoneUtil.formatForDisplay(phoneNumber);
    final carrierInfo = NigerianPhoneUtil.getCarrierInfo(carrier);

    return {
      'carrier': carrier,
      'networkType': networkType,
      'formatted': formatted,
      'carrierInfo': carrierInfo,
      'isNigerian': phoneNumber.startsWith('+234') ||
          phoneNumber.startsWith('234') ||
          phoneNumber.startsWith('0'),
    };
  }

  @override
  void dispose() {
    if (_activeCall != null) {
      endCall();
    }
    super.dispose();
  }
}
