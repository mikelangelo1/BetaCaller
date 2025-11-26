import 'package:flutter/foundation.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';
import 'package:beta_caller/utils/nigerian_phone_util.dart';

enum TelnyxCallState {
  idle,
  connecting,
  ringing,
  active,
  held,
  ended,
  failed,
}

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

class ActiveCall {
  final String callId;
  final String to;
  final String from;
  final CallRateInfo rate;
  TelnyxCallState state;
  DateTime? connectedAt;
  int durationSeconds;

  ActiveCall({
    required this.callId,
    required this.to,
    required this.from,
    required this.rate,
    this.state = TelnyxCallState.connecting,
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
}

class TelnyxCallService extends ChangeNotifier {
  final BetaCallerApiService _apiService = BetaCallerApiService();

  ActiveCall? _activeCall;
  String? _telnyxToken;
  DateTime? _tokenExpiresAt;

  ActiveCall? get activeCall => _activeCall;
  bool get hasActiveCall => _activeCall != null;
  TelnyxCallState get callState => _activeCall?.state ?? TelnyxCallState.idle;

  /// Get or refresh Telnyx token
  Future<String> _getToken() async {
    // Check if we have a valid token
    if (_telnyxToken != null && _tokenExpiresAt != null) {
      if (DateTime.now().isBefore(_tokenExpiresAt!)) {
        return _telnyxToken!;
      }
    }

    // Get new token from backend
    debugPrint('Getting new Telnyx token...');
    final response = await _apiService.getTelnyxToken();

    if (response['success'] == true) {
      _telnyxToken = response['token'] as String;
      final expiresIn = response['expiresIn'] as int? ?? 86400; // 24 hours default
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      debugPrint('Token obtained, expires at: $_tokenExpiresAt');
      return _telnyxToken!;
    } else {
      throw Exception('Failed to get Telnyx token: ${response['error']}');
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
        // Create active call object
        _activeCall = ActiveCall(
          callId: response['callId'] as String,
          to: formattedNumber,
          from: 'client',
          rate: rate,
          state: TelnyxCallState.connecting,
        );

        notifyListeners();

        // Get Telnyx token (for WebRTC)
        await _getToken();

        // In a real implementation, you would:
        // 1. Initialize WebRTC connection using the token
        // 2. Create peer connection
        // 3. Handle ICE candidates
        // 4. Connect to Telnyx SIP endpoint
        // For now, we'll simulate the call flow

        // Simulate ringing
        await Future.delayed(const Duration(seconds: 2));
        _updateCallState(TelnyxCallState.ringing);

        // Simulate answer (in real app, this comes from WebRTC events)
        await Future.delayed(const Duration(seconds: 3));
        _updateCallState(TelnyxCallState.active);
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
      _updateCallState(TelnyxCallState.ended);

      // In a real implementation:
      // 1. Close WebRTC connection
      // 2. Send hangup to Telnyx
      // 3. Wait for webhook confirmation

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
    if (_activeCall == null || _activeCall!.state != TelnyxCallState.active) {
      return;
    }

    _updateCallState(TelnyxCallState.held);
  }

  /// Resume call from hold
  Future<void> resumeCall() async {
    if (_activeCall == null || _activeCall!.state != TelnyxCallState.held) {
      return;
    }

    _updateCallState(TelnyxCallState.active);
  }

  /// Mute/unmute call
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    // In real implementation: control WebRTC audio track
    debugPrint('Mute toggled: $_isMuted');
    notifyListeners();
  }

  /// Speaker on/off
  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    // In real implementation: switch audio output
    debugPrint('Speaker toggled: $_isSpeakerOn');
    notifyListeners();
  }

  /// Send DTMF tones
  void sendDTMF(String digit) {
    if (_activeCall == null || _activeCall!.state != TelnyxCallState.active) {
      return;
    }

    // In real implementation: send DTMF via WebRTC
    debugPrint('Sending DTMF: $digit');
  }

  /// Private: Update call state
  void _updateCallState(TelnyxCallState newState) {
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
          _activeCall!.state == TelnyxCallState.ended ||
          _activeCall!.state == TelnyxCallState.failed) {
        return false; // Stop timer
      }

      if (_activeCall!.state == TelnyxCallState.active) {
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
