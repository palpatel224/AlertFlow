import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get alerts => _firestore.collection('alerts');

  /// Store or update user data
  Future<void> saveUser(UserModel user) async {
    try {
      await users.doc(user.id).set(user.toJson(), SetOptions(merge: true));
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('Failed to save user data');
    }
  }

  /// Get user data by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await users.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Store or update user profile data (alias for saveUser for auth compatibility)
  Future<void> saveUserProfile(UserModel user) async {
    return await saveUser(user);
  }

  /// Get user profile data by ID (alias for getUser for auth compatibility)
  Future<UserModel?> getUserProfile(String userId) async {
    return await getUser(userId);
  }

  /// Update user location
  Future<void> updateUserLocation(
      String userId, double latitude, double longitude) async {
    try {
      await users.doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastSeen': DateTime.now().toIso8601String(),
      });
      print('User location updated');
    } catch (e) {
      print('Error updating user location: $e');
      throw Exception('Failed to update location');
    }
  }

  /// Update FCM token
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    try {
      await users.doc(userId).update({
        'fcmToken': fcmToken,
        'lastSeen': DateTime.now().toIso8601String(),
      });
      print('FCM token updated');
    } catch (e) {
      print('Error updating FCM token: $e');
      throw Exception('Failed to update FCM token');
    }
  }

  /// Get active alerts
  Stream<List<AlertModel>> getActiveAlerts({int limit = 50}) {
    return alerts
        .where('isActive', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final allAlerts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure document ID is included
        return AlertModel.fromJson(data);
      }).toList();

      // Filter out expired alerts in code and sort by creation date
      final now = DateTime.now();
      final activeAlerts =
          allAlerts.where((alert) => alert.expiresAt.isAfter(now)).toList();

      // Sort by creation date descending (newest first)
      activeAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return activeAlerts;
    });
  }

  /// Get alerts by severity
  Stream<List<AlertModel>> getAlertsBySeverity(String severity,
      {int limit = 20}) {
    return alerts
        .where('isActive', isEqualTo: true)
        .where('severity', isEqualTo: severity)
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AlertModel.fromJson(data);
      }).toList();
    });
  }

  /// Get nearby alerts based on user location
  Future<List<AlertModel>> getNearbyAlerts(
      double userLatitude, double userLongitude, double radiusKm,
      {int limit = 20}) async {
    try {
      // Note: This is a simplified approach. For production, use geohash or GeoFlutterFire
      // for more efficient geo queries

      QuerySnapshot snapshot = await alerts
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(100) // Get more docs to filter by distance
          .get();

      List<AlertModel> allAlerts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AlertModel.fromJson(data);
      }).toList();

      // Filter by distance
      List<AlertModel> nearbyAlerts = allAlerts.where((alert) {
        if (alert.latitude == null || alert.longitude == null) return false;

        double? distance = alert.distanceFromUser(userLatitude, userLongitude);
        return distance != null && distance <= radiusKm;
      }).toList();

      // Sort by distance and limit results
      nearbyAlerts.sort((a, b) {
        double? distanceA = a.distanceFromUser(userLatitude, userLongitude);
        double? distanceB = b.distanceFromUser(userLatitude, userLongitude);

        if (distanceA == null && distanceB == null) return 0;
        if (distanceA == null) return 1;
        if (distanceB == null) return -1;

        return distanceA.compareTo(distanceB);
      });

      return nearbyAlerts.take(limit).toList();
    } catch (e) {
      print('Error getting nearby alerts: $e');
      return [];
    }
  }

  /// Get single alert by ID
  Future<AlertModel?> getAlert(String alertId) async {
    try {
      DocumentSnapshot doc = await alerts.doc(alertId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AlertModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting alert: $e');
      return null;
    }
  }

  /// Update user notification preferences
  Future<void> updateNotificationPreferences(
    String userId,
    bool notificationsEnabled,
    List<String> disasterTypes,
    double alertRadius,
  ) async {
    try {
      await users.doc(userId).update({
        'notificationsEnabled': notificationsEnabled,
        'disasterTypes': disasterTypes,
        'alertRadius': alertRadius,
        'lastSeen': DateTime.now().toIso8601String(),
      });
      print('Notification preferences updated');
    } catch (e) {
      print('Error updating notification preferences: $e');
      throw Exception('Failed to update preferences');
    }
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      await users.doc(userId).delete();
      print('User account deleted');
    } catch (e) {
      print('Error deleting user account: $e');
      throw Exception('Failed to delete account');
    }
  }
}
