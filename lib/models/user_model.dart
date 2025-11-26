class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? displayName;
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final double balance;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.profileImageUrl,
    this.firstName = '',
    this.lastName = '',
    this.balance = 0.0,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      // Support both camelCase (backend) and snake_case (legacy)
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      displayName: json['displayName'] ?? json['display_name'],
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : (json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'first_name': firstName,
      'last_name': lastName,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? profileImageUrl,
    String? firstName,
    String? lastName,
    double? balance,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
