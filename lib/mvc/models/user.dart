class User {
  final String id;
  final String username;
  final String email;
  final String? passwordHash;
  final String? deviceId;
  final String? deviceName;
  final String? deviceMacAddress;
  final String loginMethod;
  final bool isBleRegistered;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? fullName;
  final String? avatarUrl;
  final List<dynamic>? preferredWifiNetworks;
  final Map<String, dynamic>? deviceSettings;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.passwordHash,
    this.deviceId,
    this.deviceName,
    this.deviceMacAddress,
    this.loginMethod = 'credentials',
    this.isBleRegistered = false,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.fullName,
    this.avatarUrl,
    this.preferredWifiNetworks,
    this.deviceSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String?,
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      deviceMacAddress: json['device_mac_address'] as String?,
      loginMethod: json['login_method'] as String? ?? 'credentials',
      isBleRegistered: json['is_ble_registered'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'] as String) 
          : null,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredWifiNetworks: json['preferred_wifi_networks'] != null 
          ? List<dynamic>.from(json['preferred_wifi_networks'] as List) 
          : null,
      deviceSettings: json['device_settings'] != null 
          ? Map<String, dynamic>.from(json['device_settings'] as Map) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_mac_address': deviceMacAddress,
      'login_method': loginMethod,
      'is_ble_registered': isBleRegistered,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'preferred_wifi_networks': preferredWifiNetworks,
      'device_settings': deviceSettings,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    String? deviceId,
    String? deviceName,
    String? deviceMacAddress,
    String? loginMethod,
    bool? isBleRegistered,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? fullName,
    String? avatarUrl,
    List<dynamic>? preferredWifiNetworks,
    Map<String, dynamic>? deviceSettings,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceMacAddress: deviceMacAddress ?? this.deviceMacAddress,
      loginMethod: loginMethod ?? this.loginMethod,
      isBleRegistered: isBleRegistered ?? this.isBleRegistered,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredWifiNetworks: preferredWifiNetworks ?? this.preferredWifiNetworks,
      deviceSettings: deviceSettings ?? this.deviceSettings,
    );
  }
}
