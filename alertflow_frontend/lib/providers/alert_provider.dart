import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/fcm_service.dart';
import 'package:geolocator/geolocator.dart';

class AlertProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final FCMService _fcmService = FCMService();

  List<AlertModel> _alerts = [];
  List<AlertModel> _nearbyAlerts = [];
  UserModel? _currentUser;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _alertsSubscription;
  StreamSubscription? _fcmSubscription;

  // Getters
  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get nearbyAlerts => _nearbyAlerts;
  UserModel? get currentUser => _currentUser;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Location getters
  double? get userLatitude => _currentPosition?.latitude;
  double? get userLongitude => _currentPosition?.longitude;

  // Alert radius for map display (in meters)
  double get alertRadius => 50000; // 50km default radius

  // Filtered alerts by severity
  List<AlertModel> get criticalAlerts =>
      _alerts.where((alert) => alert.severity == 'critical').toList();
  List<AlertModel> get highAlerts =>
      _alerts.where((alert) => alert.severity == 'high').toList();
  List<AlertModel> get mediumAlerts =>
      _alerts.where((alert) => alert.severity == 'medium').toList();
  List<AlertModel> get lowAlerts =>
      _alerts.where((alert) => alert.severity == 'low').toList();

  /// Initialize the provider
  Future<void> initialize() async {
    setLoading(true);
    try {
      // Initialize services
      await _locationService.initialize();
      await _fcmService.initialize();

      // Start location tracking
      await _startLocationTracking();

      // Setup FCM listener
      _setupFCMListener();

      // Load initial alerts
      await _loadAlerts();

      setError(null);
    } catch (e) {
      setError('Initialization failed: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      // Get initial location
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        await _updateUserLocation(position);
      }

      // Start continuous tracking
      _locationService.startLocationTracking();
      _locationSubscription =
          _locationService.locationStream.listen((position) async {
        _currentPosition = position;
        await _updateUserLocation(position);
        await _loadNearbyAlerts(); // Refresh nearby alerts when location changes
        notifyListeners();
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Update user location in database
  Future<void> _updateUserLocation(Position position) async {
    if (_currentUser == null) return;

    try {
      await _firestoreService.updateUserLocation(
        _currentUser!.id,
        position.latitude,
        position.longitude,
      );

      _currentUser = _currentUser!.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  /// Setup FCM message listener
  void _setupFCMListener() {
    _fcmSubscription = _fcmService.messageStream.listen((alert) {
      // Add received alert to the list if not already present
      if (!_alerts.any((existingAlert) => existingAlert.id == alert.id)) {
        _alerts.insert(0, alert);
        notifyListeners();
      }
    });
  }

  /// Load all alerts
  Future<void> _loadAlerts() async {
    try {
      // Load from Firestore (real-time)
      _alertsSubscription =
          _firestoreService.getActiveAlerts(limit: 100).listen((alerts) {
        _alerts = alerts;
        notifyListeners();
        _loadNearbyAlerts(); // Update nearby alerts when all alerts change
      });
    } catch (e) {
      print('Error loading alerts: $e');
      // Fallback to API
      try {
        _alerts = await _apiService.getActiveAlerts(limit: 100);
        notifyListeners();
      } catch (apiError) {
        setError('Failed to load alerts: $apiError');
      }
    }
  }

  /// Load nearby alerts
  Future<void> _loadNearbyAlerts() async {
    if (_currentPosition == null || _currentUser == null) return;

    try {
      _nearbyAlerts = await _firestoreService.getNearbyAlerts(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentUser!.alertRadius,
        limit: 50,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading nearby alerts: $e');
    }
  }

  /// Refresh alerts manually
  Future<void> refreshAlerts() async {
    setLoading(true);
    try {
      await _loadAlerts();
      await _loadNearbyAlerts();
      setError(null);
    } catch (e) {
      setError('Failed to refresh alerts: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Get alerts by severity
  Future<List<AlertModel>> getAlertsBySeverity(String severity) async {
    try {
      return await _apiService.getAlertsBySeverity(severity);
    } catch (e) {
      print('Error getting alerts by severity: $e');
      return _alerts.where((alert) => alert.severity == severity).toList();
    }
  }

  /// Update user notification preferences
  Future<void> updateNotificationPreferences({
    required bool notificationsEnabled,
    required List<String> disasterTypes,
    required double alertRadius,
  }) async {
    if (_currentUser == null) return;

    try {
      await _firestoreService.updateNotificationPreferences(
        _currentUser!.id,
        notificationsEnabled,
        disasterTypes,
        alertRadius,
      );

      _currentUser = _currentUser!.copyWith(
        notificationsEnabled: notificationsEnabled,
        disasterTypes: disasterTypes,
        alertRadius: alertRadius,
      );

      notifyListeners();
    } catch (e) {
      setError('Failed to update preferences: $e');
    }
  }

  /// Calculate distance to alert
  double? getDistanceToAlert(AlertModel alert) {
    if (_currentPosition == null ||
        alert.latitude == null ||
        alert.longitude == null) {
      return null;
    }

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      alert.latitude!,
      alert.longitude!,
    );
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Set current user (called by auth provider)
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Update current user data
  Future<void> updateCurrentUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _alertsSubscription?.cancel();
    _fcmSubscription?.cancel();
    _locationService.stopLocationTracking();
    _fcmService.dispose();
    super.dispose();
  }
}
