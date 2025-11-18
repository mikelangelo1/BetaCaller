enum CallType { outgoing, incoming, missed }

enum CallStatus { connecting, ringing, connected, ended, failed, rejected }

class CallModel {
  final String id;
  final String contactName;
  final String phoneNumber;
  final CallType callType;
  final CallStatus callStatus;
  final DateTime timestamp;
  final int? duration; // in seconds
  final double? cost; // cost of the call
  final String? countryCode;
  final String? twilioCallSid;

  CallModel({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.callType,
    required this.callStatus,
    required this.timestamp,
    this.duration,
    this.cost,
    this.countryCode,
    this.twilioCallSid,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] ?? '',
      contactName: json['contact_name'] ?? 'Unknown',
      phoneNumber: json['phone_number'] ?? '',
      callType: CallType.values.firstWhere(
        (e) => e.name == json['call_type'],
        orElse: () => CallType.outgoing,
      ),
      callStatus: CallStatus.values.firstWhere(
        (e) => e.name == json['call_status'],
        orElse: () => CallStatus.ended,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      duration: json['duration'],
      cost: json['cost']?.toDouble(),
      countryCode: json['country_code'],
      twilioCallSid: json['twilio_call_sid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'call_type': callType.name,
      'call_status': callStatus.name,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'cost': cost,
      'country_code': countryCode,
      'twilio_call_sid': twilioCallSid,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'call_type': callType.index,
      'call_status': callStatus.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration,
      'cost': cost,
      'country_code': countryCode,
      'twilio_call_sid': twilioCallSid,
    };
  }

  factory CallModel.fromDatabase(Map<String, dynamic> map) {
    return CallModel(
      id: map['id'] ?? '',
      contactName: map['contact_name'] ?? 'Unknown',
      phoneNumber: map['phone_number'] ?? '',
      callType: CallType.values[map['call_type'] ?? 0],
      callStatus: CallStatus.values[map['call_status'] ?? 0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      duration: map['duration'],
      cost: map['cost']?.toDouble(),
      countryCode: map['country_code'],
      twilioCallSid: map['twilio_call_sid'],
    );
  }

  String get formattedDuration {
    if (duration == null || duration == 0) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedCost {
    if (cost == null) return '\$0.00';
    return '\$${cost!.toStringAsFixed(2)}';
  }
}
