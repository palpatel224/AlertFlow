import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Update this with your backend URL
  static const String baseUrl = 'http://localhost:3000/api';

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// Get all active alerts
  Future<List<AlertModel>> getActiveAlerts({int limit = 50}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/alerts?limit=$limit'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> alertsJson = data['data'];
          return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
        }
      }

      throw Exception('Failed to load alerts');
    } catch (e) {
      print('Error fetching active alerts: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get alerts by severity
  Future<List<AlertModel>> getAlertsBySeverity(String severity,
      {int limit = 20}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/alerts/severity/$severity?limit=$limit'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> alertsJson = data['data'];
          return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
        }
      }

      throw Exception('Failed to load alerts by severity');
    } catch (e) {
      print('Error fetching alerts by severity: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get nearby alerts based on location
  Future<List<AlertModel>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radius = 50.0,
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/alerts/nearby?lat=$latitude&lng=$longitude&radius=$radius&limit=$limit'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> alertsJson = data['data'];
          return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
        }
      }

      throw Exception('Failed to load nearby alerts');
    } catch (e) {
      print('Error fetching nearby alerts: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Register user location and FCM token
  Future<bool> registerUser({
    required String userId,
    double? latitude,
    double? longitude,
    String? fcmToken,
    String? name,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'userId': userId,
        'fcmToken': fcmToken,
        'name': name,
        'email': email,
        'lastSeen': DateTime.now().toIso8601String(),
      };

      // Only add location if both coordinates are provided
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/register'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  /// Update user location
  Future<bool> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/$userId/location'),
            headers: _headers,
            body: json.encode({
              'latitude': latitude,
              'longitude': longitude,
              'lastSeen': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  /// Update FCM token
  Future<bool> updateFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$userId/fcm-token'),
            headers: _headers,
            body: json.encode({
              'fcmToken': fcmToken,
              'lastSeen': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  /// Get server status
  Future<Map<String, dynamic>?> getServerStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting server status: $e');
      return null;
    }
  }

  /// Get Firebase status
  Future<Map<String, dynamic>?> getFirebaseStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/firebase/status'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting Firebase status: $e');
      return null;
    }
  }
}
