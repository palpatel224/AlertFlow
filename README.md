# 🚨 AlertFlow - Disaster Alert System

<div align="center">

![AlertFlow Logo](https://img.shields.io/badge/AlertFlow-Disaster%20Alert%20System-red?style=for-the-badge&logo=warning&logoColor=white)

[![Node.js](https://img.shields.io/badge/Node.js-16+-green?style=flat-square&logo=node.js)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%26%20FCM-orange?style=flat-square&logo=firebase)](https://firebase.google.com/)
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-AI%20Processing-purple?style=flat-square&logo=google)](https://ai.google.dev/)

</div>

AlertFlow is a comprehensive, real-time disaster alert system that automatically scrapes earthquake data from USGS, processes it using Google Gemini AI, stores alerts in Firebase Firestore, and delivers location-based push notifications to users via a Flutter mobile app.

## 🧩 Project Structure

```
AlertFlow/
├── 📱 alertflow_frontend/          # Flutter mobile application
│   ├── lib/                       # Dart source code
│   ├── android/                   # Android-specific files
│   ├── ios/                       # iOS-specific files
│   └── README.md                  # Frontend documentation
├── 🖥️ alertflow_backend/           # Node.js backend server
│   ├── services/                  # Business logic services
│   ├── config/                    # Configuration files
│   └── README.md                  # Backend documentation
├── 📋 SETUP_GUIDE.md              # Complete setup instructions
└── 📄 README.md                   # This file - project overview
```

## ✨ Key Features

### 🚨 Real-time Disaster Alerts

- **Automated Data Collection**: Continuous USGS earthquake monitoring
- **AI-Powered Processing**: Gemini AI for intelligent alert formatting
- **Location-based Targeting**: Notifications based on user proximity
- **Multi-severity Levels**: Minor, Moderate, Major, Critical classifications

### 📱 Mobile Application

- **Cross-platform Support**: Native iOS and Android apps
- **Interactive Maps**: Visual alert representation with Google Maps
- **Customizable Preferences**: Alert radius, severity filters, quiet hours
- **Secure Authentication**: Google Sign-In integration
- **Offline Capabilities**: Basic functionality without internet

### 🖥️ Backend Services

- **Scalable API**: RESTful endpoints optimized for mobile
- **Real-time Sync**: Live data updates with Firestore
- **Push Notifications**: Firebase Cloud Messaging integration
- **Performance Monitoring**: Comprehensive logging and analytics

## 🚀 Quick Start

### 📋 Prerequisites

- **Node.js** 16.0+ and **npm** 8.0+
- **Flutter** 3.0+ and **Dart** 3.0+
- **Firebase** project with Firestore and FCM
- **Google Gemini API** key

### ⚡ 5-Minute Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/AlertFlow.git
   cd AlertFlow
   ```

2. **Backend Setup** (Detailed guide: [Backend README](alertflow_backend/README.md))

   ```bash
   cd alertflow_backend
   npm install
   cp .env.example .env  # Configure your API keys
   npm start
   ```

3. **Frontend Setup** (Detailed guide: [Frontend README](alertflow_frontend/README.md))

   ```bash
   cd ../alertflow_frontend
   flutter pub get
   flutter run
   ```

4. **Complete Setup Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions

## 📚 Documentation

| Component       | Description                         | Link                                            |
| --------------- | ----------------------------------- | ----------------------------------------------- |
| 🖥️ **Backend**  | Node.js API server, data processing | [Backend README](alertflow_backend/README.md)   |
| 📱 **Frontend** | Flutter mobile application          | [Frontend README](alertflow_frontend/README.md) |
| 🔧 **Setup**    | Complete installation guide         | [SETUP_GUIDE.md](SETUP_GUIDE.md)                |

## 🌍 Technology Stack

| Layer              | Technology               | Purpose                        |
| ------------------ | ------------------------ | ------------------------------ |
| **Mobile**         | Flutter + Dart           | Cross-platform mobile app      |
| **Backend**        | Node.js + Express        | API server and data processing |
| **Database**       | Firebase Firestore       | Real-time NoSQL database       |
| **Authentication** | Firebase Auth            | Secure user management         |
| **Messaging**      | Firebase Cloud Messaging | Push notifications             |
| **AI Processing**  | Google Gemini API        | Alert analysis and formatting  |
| **Maps**           | Google Maps API          | Location visualization         |
| **Data Source**    | USGS Earthquake API      | Real-time earthquake data      |

## 📊 System Capabilities

- **🌐 Global Coverage**: Worldwide earthquake monitoring
- **⚡ Real-time Processing**: Sub-5-second alert delivery
- **📍 Precision Targeting**: Location-based notifications (10-200km radius)
- **🔄 High Availability**: 99.9% uptime target
- **📈 Scalable**: Supports thousands of concurrent users
- **🛡️ Secure**: Enterprise-grade security measures



## 🙏 Acknowledgments

- **USGS** for providing earthquake data APIs
- **Google** for Gemini AI and Firebase services
- **Flutter Team** for the amazing mobile framework
- **Open Source Community** for the incredible tools and libraries

---

<div align="center">

**🌍 Built with ❤️ for disaster preparedness and community safety**

[🚀 Get Started](SETUP_GUIDE.md) | [📱 Frontend Docs](alertflow_frontend/README.md) | [🖥️ Backend Docs](alertflow_backend/README.md)

</div>
