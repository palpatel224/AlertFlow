import 'dart:math';
import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String disasterType;
  final double? latitude;
  final double? longitude;
  final String location;
  final String date;
  final String time;
  final String magnitude;
  final String severity;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String source;
  final bool notificationSent;
  final String? description;
  final String? depth;

  AlertModel({
    required this.id,
    required this.disasterType,
    this.latitude,
    this.longitude,
    required this.location,
    required this.date,
    required this.time,
    required this.magnitude,
    required this.severity,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.source,
    required this.notificationSent,
    this.description,
    this.depth,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      disasterType: json['disasterType'] ?? 'Unknown',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      location: json['location'] ?? 'Unknown Location',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      magnitude: json['magnitude']?.toString() ?? 'Unknown',
      severity: json['severity'] ?? 'medium',
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      isActive: json['isActive'] ?? true,
      source: json['source'] ?? 'Unknown',
      notificationSent: json['notificationSent'] ?? false,
      description: json['description'],
      depth: json['depth']?.toString(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(hours: 24));

    // Handle Firestore Timestamp using type check
    if (value.toString().contains('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (e) {
        print('Error parsing Timestamp: $e');
        return DateTime.now();
      }
    }

    // Handle String
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing DateTime string: $e');
        return DateTime.now();
      }
    }

    // Try to parse as DateTime object
    if (value is DateTime) {
      return value;
    }

    // Fallback
    print('Unknown datetime type: ${value.runtimeType}');
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disasterType': disasterType,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'date': date,
      'time': time,
      'magnitude': magnitude,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'source': source,
      'notificationSent': notificationSent,
      'description': description,
      'depth': depth,
    };
  }

  // Calculate distance from user's location
  double? distanceFromUser(double? userLat, double? userLng) {
    if (latitude == null ||
        longitude == null ||
        userLat == null ||
        userLng == null) {
      return null;
    }

    // Simple distance calculation (Haversine formula would be more accurate)
    const double earthRadius = 6371; // km
    double dLat = _toRadians(latitude! - userLat);
    double dLng = _toRadians(longitude! - userLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(userLat)) *
            cos(_toRadians(latitude!)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Calculate distance from user's location (method for compatibility)
  double? calculateDistance(double? userLat, double? userLng) {
    return distanceFromUser(userLat, userLng);
  }

  // Get formatted time
  String get formattedTime {
    return '$date $time';
  }

  // Get severity color
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get disaster type icon
  IconData get disasterIcon {
    switch (disasterType.toLowerCase()) {
      case 'earthquake':
        return Icons.landscape;
      case 'cyclone':
      case 'hurricane':
        return Icons.cyclone;
      case 'flood':
        return Icons.water;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.warning;
    }
  }
}
