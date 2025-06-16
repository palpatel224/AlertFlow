# 📱 AlertFlow Frontend

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?style=for-the-badge&logo=flutter)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20FCM-orange?style=flat-square&logo=firebase)](https://firebase.google.com/)
[![Google Maps](https://img.shields.io/badge/Maps-Google%20Maps-green?style=flat-square&logo=googlemaps)](https://developers.google.com/maps)

</div>

A beautiful, cross-platform Flutter mobile application that delivers real-time disaster alerts with location-based targeting, interactive maps, and customizable user preferences. Built for both iOS and Android with a focus on performance, usability, and reliability.

## ✨ Features

### 🚨 Core Alert Features

- **Real-time Disaster Alerts**: Instant notifications for earthquakes and other disasters
- **Location-based Filtering**: Receive alerts within your customizable radius (10-200km)
- **Severity Classification**: Filter by Minor, Moderate, Major, Critical levels
- **Interactive Maps**: Visual alert representation with Google Maps integration
- **Detailed Alert Info**: Comprehensive safety guidelines and emergency instructions

### 🎨 User Experience

- **Beautiful Material Design**: Modern UI following Material Design 3 guidelines
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Smooth Animations**: Delightful micro-interactions and transitions
- **Accessibility**: Full screen reader support and high contrast options
- **Responsive Design**: Optimized for phones and tablets

### ⚙️ Customization & Settings

- **User Preferences**: Customizable alert radius, severity filters, and notification settings
- **Quiet Hours**: Schedule do-not-disturb periods
- **Sound & Vibration**: Configurable notification behaviors
- **Location Privacy**: Granular location sharing controls


## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.16.0 or higher
- **Dart SDK** 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Firebase project** configured for your app

### Installation

1. **Navigate to frontend directory**

   ```bash
   cd alertflow_frontend
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**

   Set up Firebase for your Flutter app:

   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Configure Google Maps** (Optional but recommended)

   Add your Google Maps API key:

   **Android** - `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY" />
   ```

   **iOS** - `ios/Runner/AppDelegate.swift`:

   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

5. **Update API Configuration**

   Edit `lib/config/app_config.dart`:

   ```dart
   class AppConfig {
     static const String baseUrl = 'http://localhost:3000'; // Development
     // static const String baseUrl = 'https://your-api.com'; // Production
     static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
   }
   ```

6. **Run the application**

   ```bash
   # Check available devices
   flutter devices

   # Run on debug mode
   flutter run

   # Run on specific device
   flutter run -d device_id

   # Run on Android
   flutter run -d android

   # Run on iOS (macOS only)
   flutter run -d ios
   ```

## 📁 Project Structure

```
alertflow_frontend/
├── 📁 lib/
│   ├── 📄 main.dart                    # App entry point
│   ├── 📄 firebase_options.dart        # Firebase configuration
│   ├── 📁 config/
│   │   ├── 📄 app_config.dart          # App configuration
│   │   ├── 📄 theme.dart               # App theming
│   │   └── 📄 routes.dart              # App routing
│   ├── 📁 models/
│   │   ├── 📄 alert_model.dart         # Alert data model
│   │   ├── 📄 user_model.dart          # User data model
│   │   └── 📄 location_model.dart      # Location data model
│   ├── 📁 services/
│   │   ├── 📄 api_service.dart         # Backend API communication
│   │   ├── 📄 auth_service.dart        # Authentication service
│   │   ├── 📄 location_service.dart    # Location tracking
│   │   ├── 📄 notification_service.dart # Notification handling
│   │   └── 📄 fcm_service.dart         # Firebase messaging
│   ├── 📁 providers/
│   │   ├── 📄 alert_provider.dart      # Alert state management
│   │   ├── 📄 auth_provider.dart       # Auth state management
│   │   ├── 📄 location_provider.dart   # Location state management
│   │   └── 📄 theme_provider.dart      # Theme state management
│   ├── 📁 screens/
│   │   ├── 📄 splash_screen.dart       # App splash screen
│   │   ├── 📄 auth_wrapper.dart        # Authentication wrapper
│   │   ├── 📄 login_screen.dart        # Login interface
│   │   ├── 📄 home_screen.dart         # Main dashboard
│   │   ├── 📄 map_screen.dart          # Interactive map
│   │   ├── 📄 alerts_screen.dart       # Alert list view
│   │   ├── 📄 alert_detail_screen.dart # Alert details
│   │   ├── 📄 settings_screen.dart     # User settings
│   │   └── 📄 profile_screen.dart      # User profile
│   ├── 📁 widgets/
│   │   ├── 📄 alert_card.dart          # Alert display card
│   │   ├── 📄 map_widget.dart          # Map component
│   │   ├── 📄 custom_app_bar.dart      # Custom app bar
│   │   ├── 📄 loading_widget.dart      # Loading indicators
│   │   └── 📄 error_widget.dart        # Error displays
│   └── 📁 utils/
│       ├── 📄 constants.dart           # App constants
│       ├── 📄 helpers.dart             # Utility functions
│       ├── 📄 validators.dart          # Input validation
│       └── 📄 date_utils.dart          # Date formatting
├── 📁 android/                        # Android-specific files
├── 📁 ios/                            # iOS-specific files
├── 📁 test/                           # Unit and widget tests
├── 📁 integration_test/               # Integration tests
├── 📄 pubspec.yaml                    # Dependencies and configuration
└── 📄 README.md                       # This file
```

<div align="center">

**📱 Built with Flutter for a beautiful, native experience**

[🏠 Main Project](../README.md) | [🖥️ Backend Docs](../alertflow_backend/README.md) | [🔧 Setup Guide](../SETUP_GUIDE.md)

</div>
