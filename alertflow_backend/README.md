# 🖥️ AlertFlow Backend

<div align="center">

![Backend](https://img.shields.io/badge/Backend-Node.js%20%26%20Express-green?style=for-the-badge&logo=node.js)
[![Firebase](https://img.shields.io/badge/Database-Firebase%20Firestore-orange?style=flat-square&logo=firebase)](https://firebase.google.com/)
[![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-purple?style=flat-square&logo=google)](https://ai.google.dev/)

</div>

A powerful Node.js backend service that scrapes disaster alerts, processes them using Google's Gemini AI, stores them in Firebase Firestore, and sends intelligent push notifications via Firebase Cloud Messaging (FCM).

## 🚀 Features

- 🌍 **Automated Data Scraping**: Real-time USGS earthquake data collection using Puppeteer
- 🤖 **AI-Powered Processing**: Google Gemini AI for intelligent alert analysis and formatting
- 🔥 **Firebase Integration**: Seamless Firestore database with automatic TTL expiration
- 📱 **Smart Notifications**: Location-based FCM push notifications with user preferences
- 🎯 **Intelligent Targeting**: Advanced filtering by disaster type, severity, and user location
- 🔄 **Batch Processing**: Efficient handling of multiple alerts simultaneously
- 📊 **RESTful API**: Comprehensive endpoints for mobile app integration


## 📦 Tech Stack

| Component          | Technology               | Purpose                               |
| ------------------ | ------------------------ | ------------------------------------- |
| **Runtime**        | Node.js 16+              | JavaScript runtime environment        |
| **Framework**      | Express.js               | Web application framework             |
| **Database**       | Firebase Firestore       | NoSQL document database               |
| **Authentication** | Firebase Auth            | User authentication & authorization   |
| **Messaging**      | Firebase Cloud Messaging | Push notifications                    |
| **AI Processing**  | Google Gemini API        | Natural language processing           |
| **Web Scraping**   | Puppeteer                | Automated browser for data extraction |
| **HTTP Client**    | Axios                    | Promise-based HTTP client             |
| **Environment**    | dotenv                   | Environment variable management       |

## 🚀 Quick Start

### Prerequisites

- **Node.js** 16.0 or higher
- **npm** 8.0 or higher
- **Firebase** project with Firestore and FCM enabled
- **Google Gemini API** key

### Installation

1. **Navigate to backend directory**

   ```bash
   cd alertflow_backend
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Environment Configuration**

   Create a `.env` file in the root directory:

   ```env
   # Firebase Configuration
   FIREBASE_SERVICE_ACCOUNT_KEY=your_firebase_service_account_json_here
   FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com/

   # Google Gemini AI Configuration
   GEMINI_API_KEY=your_gemini_api_key_here

   # Server Configuration
   PORT=3000
   NODE_ENV=development

   # Scraping Configuration
   SCRAPING_INTERVAL=300000  # 5 minutes
   ALERT_EXPIRY_HOURS=24
   ENABLE_AUTO_SCRAPE=false

   # Optional: Performance & Monitoring
   LOG_LEVEL=info
   MAX_ALERTS_PER_FETCH=50
   NOTIFICATION_BATCH_SIZE=500
   ```

4. **Firebase Setup**

   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Firestore Database and Cloud Messaging
   - Download service account key JSON
   - Set the JSON content as `FIREBASE_SERVICE_ACCOUNT_KEY` in your `.env` file

5. **Test the setup**

   ```bash
   # Test Firebase connection
   npm run test-firebase

   # Test basic functionality
   npm test
   ```

6. **Start the server**

   ```bash
   # Development mode (with auto-reload)
   npm run dev

   # Production mode
   npm start

   # Development with auto-scraping enabled
   npm run dev-with-scrape
   ```

The server will start at `http://localhost:3000`

## 📖 API Documentation

### 🏥 Health & Status

| Endpoint               | Method | Description                |
| ---------------------- | ------ | -------------------------- |
| `/health`              | GET    | Basic health check         |
| `/api/firebase/status` | GET    | Firebase connection status |

### 🚨 Alert Management

| Endpoint                      | Method | Description               | Parameters                                |
| ----------------------------- | ------ | ------------------------- | ----------------------------------------- |
| `/api/alerts`                 | GET    | Get all active alerts     | `?limit=50&offset=0`                      |
| `/api/alerts/severity/:level` | GET    | Get alerts by severity    | `level: minor\|moderate\|major\|critical` |
| `/api/alerts/:id`             | GET    | Get specific alert        | `id: string`                              |
| `/api/alerts/process`         | POST   | Process new alert (admin) | Alert data in body                        |

### � User Management

| Endpoint                           | Method | Description          | Body/Parameters                  |
| ---------------------------------- | ------ | -------------------- | -------------------------------- |
| `/api/users/register`              | POST   | Register new user    | `{ userId, fcmToken, location }` |
| `/api/users/:userId`               | GET    | Get user profile     | -                                |
| `/api/users/:userId/location`      | PUT    | Update user location | `{ latitude, longitude }`        |
| `/api/users/:userId/preferences`   | PUT    | Update preferences   | User preferences object          |
| `/api/users/:userId/alerts/nearby` | GET    | Get nearby alerts    | `?radius=50&severity=major`      |

### 📡 Notifications

| Endpoint                       | Method | Description               | Body                            |
| ------------------------------ | ------ | ------------------------- | ------------------------------- |
| `/api/notifications/send`      | POST   | Send notification (admin) | `{ userId, message, data }`     |
| `/api/notifications/broadcast` | POST   | Broadcast to area         | `{ location, radius, message }` |
| `/api/users/:userId/fcm-token` | PUT    | Update FCM token          | `{ fcmToken }`                  |

## ⚙️ Configuration

### Environment Variables

| Variable                       | Description                          | Required | Default       |
| ------------------------------ | ------------------------------------ | -------- | ------------- |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Firebase service account JSON        | ✅       | -             |
| `GEMINI_API_KEY`               | Google Gemini API key                | ✅       | -             |
| `FIREBASE_DATABASE_URL`        | Firebase Realtime Database URL       | ❌       | Auto-detected |
| `PORT`                         | Server port                          | ❌       | `3000`        |
| `NODE_ENV`                     | Environment (development/production) | ❌       | `development` |
| `SCRAPING_INTERVAL`            | Auto-scraping interval (ms)          | ❌       | `300000`      |
| `ALERT_EXPIRY_HOURS`           | Alert expiration time                | ❌       | `24`          |
| `ENABLE_AUTO_SCRAPE`           | Enable automatic scraping            | ❌       | `false`       |
| `LOG_LEVEL`                    | Logging level                        | ❌       | `info`        |
| `MAX_ALERTS_PER_FETCH`         | Max alerts per API call              | ❌       | `50`          |
| `NOTIFICATION_BATCH_SIZE`      | FCM batch size                       | ❌       | `500`         |


## 🛠️ Scripts

| Script        | Command                 | Description                    |
| ------------- | ----------------------- | ------------------------------ |
| Start         | `npm start`             | Start production server        |
| Development   | `npm run dev`           | Start with nodemon auto-reload |
| Test          | `npm test`              | Run test suite                 |
| Scrape        | `npm run scrape`        | Manual data scraping           |
| Setup         | `npm run setup`         | Initial project setup          |
| Firebase Test | `npm run test-firebase` | Test Firebase connection       |

## 📁 Project Structure

```
alertflow_backend/
├── 📄 server.js              # Main application entry point
├── 📄 scrape.js              # Data scraping functionality
├── 📄 geminiResponse.js      # Gemini AI integration
├── 📄 package.json           # Dependencies and scripts
├── 📄 .env                   # Environment variables
├── 📄 firestore.rules        # Firestore security rules
├── 📁 config/
│   └── 📄 firebase.js        # Firebase configuration
├── 📁 services/
│   ├── 📄 alertService.js    # Alert processing logic
│   ├── 📄 alertFormatter.js  # Alert data formatting
│   ├── 📄 fcmService.js      # Push notification service
│   └── 📄 firestoreService.js # Database operations
├── 📁 middleware/
│   ├── 📄 auth.js           # Authentication middleware
│   ├── 📄 validation.js     # Input validation
│   └── 📄 rateLimit.js      # Rate limiting
├── 📁 utils/
│   ├── 📄 logger.js         # Logging configuration
│   └── 📄 helpers.js        # Utility functions
└── 📁 test/
    ├── 📄 api.test.js       # API endpoint tests
    ├── 📄 scraper.test.js   # Scraping functionality tests
    └── 📄 firebase.test.js  # Firebase integration tests
```

<div align="center">

**⚡ Built for performance, reliability, and scalability**

[🏠 Main Project](../README.md) | [📱 Frontend Docs](../alertflow_frontend/README.md) | [🔧 Setup Guide](../SETUP_GUIDE.md)


