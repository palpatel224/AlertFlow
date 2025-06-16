class UserModel {
  final String id;
  final String? name;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? fcmToken;
  final DateTime lastSeen;
  final bool notificationsEnabled;
  final List<String>
      disasterTypes; // Types of disasters user wants to be notified about
  final double alertRadius; // Radius in km for location-based alerts

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.latitude,
    this.longitude,
    this.fcmToken,
    required this.lastSeen,
    this.notificationsEnabled = true,
    this.disasterTypes = const ['earthquake', 'cyclone', 'flood', 'fire'],
    this.alertRadius = 50.0, // Default 50km radius
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      fcmToken: json['fcmToken'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      disasterTypes: List<String>.from(
          json['disasterTypes'] ?? ['earthquake', 'cyclone', 'flood', 'fire']),
      alertRadius: json['alertRadius']?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'fcmToken': fcmToken,
      'lastSeen': lastSeen.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'disasterTypes': disasterTypes,
      'alertRadius': alertRadius,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? latitude,
    double? longitude,
    String? fcmToken,
    DateTime? lastSeen,
    bool? notificationsEnabled,
    List<String>? disasterTypes,
    double? alertRadius,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fcmToken: fcmToken ?? this.fcmToken,
      lastSeen: lastSeen ?? this.lastSeen,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      disasterTypes: disasterTypes ?? this.disasterTypes,
      alertRadius: alertRadius ?? this.alertRadius,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}
