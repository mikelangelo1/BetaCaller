import 'package:flutter/foundation.dart';
import 'package:beta_caller/models/call_model.dart';
import 'package:beta_caller/services/voip_call_service.dart';
import 'package:beta_caller/services/database_service.dart';

class CallProvider with ChangeNotifier {
  final VoipCallService _voipService = VoipCallService();
  final DatabaseService _databaseService = DatabaseService();

  CallModel? _activeCall;
  List<CallModel> _callHistory = [];
  bool _isInitialized = false;
  bool _isCallInProgress = false;

  CallModel? get activeCall => _activeCall;
  List<CallModel> get callHistory => _callHistory;
  bool get isInitialized => _isInitialized;
  bool get isCallInProgress => _isCallInProgress;

  CallProvider() {
    // Don't auto-initialize to prevent app startup crashes
    // Initialization will happen after login
    debugPrint('CallProvider created');
  }

  /// Get the VoIP service for direct access if needed
  VoipCallService get voipService => _voipService;

  /// Get current VoIP provider name
  String? get currentProviderName {
    final provider = _voipService.currentProvider;
    if (provider == null) return null;
    switch (provider) {
      case VoipProvider.voximplant:
        return 'Voximplant';
      case VoipProvider.twilio:
        return 'Twilio';
      case VoipProvider.telnyx:
        return 'Telnyx';
    }
  }

  Future<void> _initializeDemo() async {
    try {
      // VoIP service doesn't need explicit initialization
      // Token is fetched on demand from the backend
      await loadCallHistory();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-initializing call provider: $e');
    }
  }

  Future<void> initialize([String? token]) async {
    try {
      // VoIP service handles token management internally
      await loadCallHistory();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing call provider: $e');
    }
  }

  Future<void> makeCall(String phoneNumber, String contactName) async {
    try {
      _isCallInProgress = true;

      _activeCall = CallModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactName: contactName,
        phoneNumber: phoneNumber,
        callType: CallType.outgoing,
        callStatus: CallStatus.connecting,
        timestamp: DateTime.now(),
      );

      notifyListeners();

      // Make the call using the VoIP service (multi-provider with failover)
      await _voipService.initiateCall(to: phoneNumber, contactName: contactName);

      // Update call status based on VoIP service state
      _activeCall = _activeCall!.copyWith(callStatus: CallStatus.ringing);
      notifyListeners();

      // Listen to call state changes from VoIP service
      _voipService.addListener(_onVoipStateChanged);
    } catch (e) {
      debugPrint('Error making call: $e');
      _activeCall = _activeCall?.copyWith(callStatus: CallStatus.failed);
      _isCallInProgress = false;
      if (_activeCall != null) {
        await _saveCallToHistory(_activeCall!);
      }
      _activeCall = null;
      notifyListeners();
      rethrow;
    }
  }

  void _onVoipStateChanged() {
    if (_activeCall == null) return;

    final voipCall = _voipService.activeCall;
    if (voipCall == null) return;

    // Map VoIP call state to CallStatus
    CallStatus newStatus;
    switch (voipCall.state) {
      case VoipCallState.connecting:
        newStatus = CallStatus.connecting;
        break;
      case VoipCallState.ringing:
        newStatus = CallStatus.ringing;
        break;
      case VoipCallState.active:
        newStatus = CallStatus.inProgress;
        break;
      case VoipCallState.held:
        newStatus = CallStatus.onHold;
        break;
      case VoipCallState.ended:
        newStatus = CallStatus.ended;
        break;
      case VoipCallState.failed:
        newStatus = CallStatus.failed;
        break;
      default:
        newStatus = _activeCall!.callStatus;
    }

    _activeCall = _activeCall!.copyWith(
      callStatus: newStatus,
      duration: voipCall.durationSeconds,
      cost: voipCall.estimatedCost,
    );
    notifyListeners();
  }

  Future<void> endCall() async {
    if (_activeCall == null) return;

    try {
      // Stop listening to VoIP state changes
      _voipService.removeListener(_onVoipStateChanged);

      await _voipService.endCall();

      final endedCall = _activeCall!.copyWith(callStatus: CallStatus.ended);
      await _saveCallToHistory(endedCall);

      _activeCall = null;
      _isCallInProgress = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  void updateCallStatus(CallStatus status) {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(callStatus: status);
      notifyListeners();
    }
  }

  void updateCallDuration(int duration) {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(duration: duration);
      notifyListeners();
    }
  }

  Future<void> _saveCallToHistory(CallModel call) async {
    try {
      await _databaseService.insertCall(call);
      await loadCallHistory();
    } catch (e) {
      debugPrint('Error saving call to history: $e');
    }
  }

  Future<void> loadCallHistory() async {
    try {
      _callHistory = await _databaseService.getCallHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading call history: $e');
    }
  }

  Future<void> deleteCallFromHistory(String callId) async {
    try {
      await _databaseService.deleteCall(callId);
      await loadCallHistory();
    } catch (e) {
      debugPrint('Error deleting call: $e');
    }
  }

  Future<void> deleteMultipleCallsFromHistory(List<String> callIds) async {
    try {
      await _databaseService.deleteMultipleCalls(callIds);
      await loadCallHistory();
    } catch (e) {
      debugPrint('Error deleting multiple calls: $e');
    }
  }

  Future<void> clearCallHistory() async {
    try {
      await _databaseService.clearCallHistory();
      _callHistory = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing call history: $e');
    }
  }

  Future<Map<String, dynamic>> getCallStatistics() async {
    try {
      return await _databaseService.getCallStatistics();
    } catch (e) {
      debugPrint('Error getting call statistics: $e');
      return {
        'total_calls': 0,
        'total_duration': 0,
        'total_cost': 0.0,
      };
    }
  }

  List<CallModel> getRecentCalls({int limit = 10}) {
    return _callHistory.take(limit).toList();
  }

  List<CallModel> getMissedCalls() {
    return _callHistory
        .where((call) => call.callType == CallType.missed)
        .toList();
  }
}

extension CallModelCopyWith on CallModel {
  CallModel copyWith({
    String? id,
    String? contactName,
    String? phoneNumber,
    CallType? callType,
    CallStatus? callStatus,
    DateTime? timestamp,
    int? duration,
    double? cost,
    String? countryCode,
    String? twilioCallSid,
  }) {
    return CallModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      cost: cost ?? this.cost,
      countryCode: countryCode ?? this.countryCode,
      twilioCallSid: twilioCallSid ?? this.twilioCallSid,
    );
  }
}
