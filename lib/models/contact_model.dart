class ContactModel {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final bool isFavorite;
  final DateTime? lastCallDate;
  final int callCount;

  ContactModel({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.isFavorite = false,
    this.lastCallDate,
    this.callCount = 0,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'Unknown',
      phoneNumber: json['phone_number'],
      email: json['email'],
      photoUrl: json['photo_url'],
      isFavorite: json['is_favorite'] ?? false,
      lastCallDate: json['last_call_date'] != null
          ? DateTime.parse(json['last_call_date'])
          : null,
      callCount: json['call_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'email': email,
      'photo_url': photoUrl,
      'is_favorite': isFavorite,
      'last_call_date': lastCallDate?.toIso8601String(),
      'call_count': callCount,
    };
  }

  ContactModel copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    bool? isFavorite,
    DateTime? lastCallDate,
    int? callCount,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastCallDate: lastCallDate ?? this.lastCallDate,
      callCount: callCount ?? this.callCount,
    );
  }

  String get initials {
    if (displayName.isEmpty) return '?';
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }
}
