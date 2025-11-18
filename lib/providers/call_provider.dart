import 'package:flutter/foundation.dart';
import 'package:beta_caller/models/call_model.dart';
import 'package:beta_caller/services/twilio_service.dart';
import 'package:beta_caller/services/database_service.dart';

class CallProvider with ChangeNotifier {
  final TwilioService _twilioService = TwilioService();
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
    // Auto-initialize with demo token
    _initializeDemo();
  }

  Future<void> _initializeDemo() async {
    try {
      await _twilioService.initialize('demo-token-for-testing');
      await loadCallHistory();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-initializing call provider: $e');
    }
  }

  Future<void> initialize(String twilioToken) async {
    try {
      await _twilioService.initialize(twilioToken);
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

      // Make the call using Twilio
      final success = await _twilioService.makeCall(phoneNumber);

      if (success) {
        _activeCall = _activeCall!.copyWith(callStatus: CallStatus.ringing);
        notifyListeners();
      } else {
        _activeCall = _activeCall!.copyWith(callStatus: CallStatus.failed);
        _isCallInProgress = false;
        await _saveCallToHistory(_activeCall!);
        _activeCall = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      _isCallInProgress = false;
      _activeCall = null;
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    if (_activeCall == null) return;

    try {
      await _twilioService.endCall();

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

  Future<void> clearCallHistory() async {
    try {
      await _databaseService.clearCallHistory();
      _callHistory = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing call history: $e');
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
