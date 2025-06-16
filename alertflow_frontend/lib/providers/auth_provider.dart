import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/fcm_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;

  /// Initialize auth provider
  void initialize() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });

    // Set initial user if already signed in
    _user = _authService.currentUser;
    if (_user != null) {
      _loadUserProfile(_user!.uid);
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      _userProfile = await _firestoreService.getUserProfile(userId);
      if (_userProfile == null && _user != null) {
        // Create user profile if it doesn't exist
        await _createUserProfile();
      }

      // Initialize location and FCM after profile is loaded
      if (_userProfile != null) {
        await initializeLocationAndFCM();
        // Also register/update with backend
        await _registerUserWithBackend();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile() async {
    if (_user == null) return;

    try {
      final userProfile = UserModel(
        id: _user!.uid,
        name: _user!.displayName ?? '',
        email: _user!.email ?? '',
        lastSeen: DateTime.now(),
        notificationsEnabled: true,
        disasterTypes: ['earthquake', 'cyclone', 'flood', 'fire'],
        alertRadius: 50.0,
      );

      await _firestoreService.saveUserProfile(userProfile);
      _userProfile = userProfile;

      // Initialize location and FCM after profile creation
      await initializeLocationAndFCM();

      // Register with backend API
      await _registerUserWithBackend();

      notifyListeners();
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    setError(null);

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        await _loadUserProfile(credential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Create account with email and password
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    setLoading(true);
    setError(null);

    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential?.user != null) {
        await _createUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    setLoading(true);
    setError(null);

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential?.user != null) {
        await _loadUserProfile(credential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    setLoading(true);
    setError(null);

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserModel updatedProfile) async {
    setLoading(true);
    setError(null);

    try {
      await _firestoreService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to update profile: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Update user location
  Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_userProfile == null) return false;

    try {
      final updatedProfile = _userProfile!.copyWith(
        latitude: latitude,
        longitude: longitude,
        lastSeen: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  /// Update FCM token
  Future<bool> updateFCMToken(String fcmToken) async {
    if (_userProfile == null) return false;

    try {
      final updatedProfile = _userProfile!.copyWith(
        fcmToken: fcmToken,
        lastSeen: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      setError('Failed to sign out: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Initialize location and FCM token updates
  Future<void> initializeLocationAndFCM({BuildContext? context}) async {
    if (_userProfile == null || _user == null) return;

    try {
      // Initialize services
      final locationService = LocationService();
      final fcmService = FCMService();

      // Initialize location service and request permissions
      bool locationInitialized;
      if (context != null) {
        locationInitialized =
            await locationService.initializeWithContext(context);
      } else {
        locationInitialized = await locationService.initialize();
      }

      bool fcmInitialized = await fcmService.initialize();

      print('Location initialized: $locationInitialized');
      print('FCM initialized: $fcmInitialized');

      // Get FCM token and update if available
      if (fcmInitialized && fcmService.fcmToken != null) {
        print('FCM Token: ${fcmService.fcmToken}');
        if (fcmService.fcmToken != _userProfile!.fcmToken) {
          await updateFCMToken(fcmService.fcmToken!);
        }
      } else {
        print('FCM token is null');
      }

      // Get current location and update if available
      if (locationInitialized) {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          print('Got location: ${position.latitude}, ${position.longitude}');
          await updateUserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } else {
          print('Failed to get current location');
        }

        // Start location tracking for future updates
        locationService.startLocationTracking();
        locationService.locationStream.listen((position) {
          print('Location update: ${position.latitude}, ${position.longitude}');
          updateUserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });
      } else {
        print('Location service initialization failed');
      }
    } catch (e) {
      print('Error initializing location and FCM: $e');
    }
  }

  /// Register user with backend API
  Future<void> _registerUserWithBackend() async {
    if (_user == null || _userProfile == null) return;

    try {
      final apiService = ApiService();
      final fcmService = FCMService();
      final locationService = LocationService();

      // Get current position
      final position = await locationService.getCurrentLocation();

      bool success = await apiService.registerUser(
        userId: _user!.uid,
        latitude: position?.latitude,
        longitude: position?.longitude,
        fcmToken: fcmService.fcmToken,
        email: _user!.email,
      );

      if (success) {
        print('User registered with backend successfully');
      } else {
        print('Failed to register user with backend');
      }
    } catch (e) {
      print('Error registering user with backend: $e');
    }
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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
