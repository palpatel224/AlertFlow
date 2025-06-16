const express = require('express');
const cors = require('cors');
const AlertService = require('./services/alertService');
const { isDemo, testFirebaseConnection } = require('./config/firebase');
const { runScraping } = require('./scrape');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const alertService = new AlertService();

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'AlertFlow Backend'
  });
});

// Firebase status endpoint
app.get('/api/firebase/status', async (req, res) => {
  try {
    if (isDemo) {
      return res.json({
        status: 'demo',
        message: 'Running in demo mode - Firebase not configured',
        timestamp: new Date().toISOString()
      });
    }w
    
    const connected = await testFirebaseConnection();
    res.json({
      status: connected ? 'connected' : 'disconnected',
      firebase: {
        connected,
        projectId: process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? 
          JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY).project_id : 'Unknown',
        databaseUrl: process.env.FIREBASE_DATABASE_URL
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get active alerts
app.get('/api/alerts', async (req, res) => {
  try {
    const { severity, limit } = req.query;
    const alerts = await alertService.getActiveAlerts({ 
      severity, 
      limit: limit ? parseInt(limit) : 50 
    });
    
    res.json({
      success: true,
      count: alerts.length,
      data: alerts
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get alerts by severity
app.get('/api/alerts/severity/:severity', async (req, res) => {
  try {
    const { severity } = req.params;
    const { limit } = req.query;
    
    const alerts = await alertService.getActiveAlerts({ 
      severity, 
      limit: limit ? parseInt(limit) : 20 
    });
    
    res.json({
      success: true,
      severity,
      count: alerts.length,
      data: alerts
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Test notification endpoint
app.post('/api/test/notification', async (req, res) => {
  try {
    const { fcmToken } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required'
      });
    }
    
    const result = await alertService.testNotificationSystem(fcmToken);
    
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Manual scraping trigger endpoint
app.post('/api/scrape', async (req, res) => {
  try {
    console.log('🚀 Manual scraping triggered via API endpoint...');
    await runScraping();
    
    res.json({
      success: true,
      message: 'Scraping completed successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Manual scraping failed:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Store user token endpoint
app.post('/api/users/:userId/token', async (req, res) => {
  try {
    const { userId } = req.params;
    const { fcmToken, preferences } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required'
      });
    }
    
    await alertService.storeTestUser(userId, fcmToken, preferences);
    
    res.json({
      success: true,
      message: 'User token stored successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Process alerts manually (for testing)
app.post('/api/alerts/process', async (req, res) => {
  try {
    const { geminiResponse } = req.body;
    
    if (!geminiResponse) {
      return res.status(400).json({
        success: false,
        error: 'Gemini response is required'
      });
    }
    
    const result = await alertService.processAlerts(geminiResponse);
    
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// User registration endpoint
app.post('/api/users/register', async (req, res) => {
  try {
    const { userId, fcmToken, latitude, longitude, preferences } = req.body;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required'
      });
    }
    
    // Validate location data if provided
    if ((latitude && !longitude) || (!latitude && longitude)) {
      return res.status(400).json({
        success: false,
        error: 'Both latitude and longitude must be provided together'
      });
    }
    
    const userData = {
      userId,
      fcmToken: fcmToken || null,
      location: {
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        lastUpdated: new Date().toISOString()
      },
      preferences: preferences || {
        enableNotifications: true,
        alertRadius: 50,
        severityFilter: ['major', 'critical'],
        quietHours: {
          enabled: false,
          start: '22:00',
          end: '07:00'
        }
      },
      registeredAt: new Date().toISOString(),
      lastActiveAt: new Date().toISOString()
    };
    
    const result = await alertService.firestoreService.saveUser(userData);
    
    res.json({
      success: true,
      data: result,
      message: 'User registered/updated successfully'
    });
  } catch (error) {
    console.error('User registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Update user location endpoint
app.post('/api/users/:userId/location', async (req, res) => {
  try {
    const { userId } = req.params;
    const { latitude, longitude } = req.body;
    
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: 'Latitude and longitude are required'
      });
    }
    
    // Validate numeric values
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({
        success: false,
        error: 'Latitude and longitude must be valid numbers'
      });
    }
    
    // Validate coordinate ranges
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinate ranges'
      });
    }
    
    const locationData = {
      latitude: lat,
      longitude: lng,
      lastUpdated: new Date().toISOString()
    };
    
    const result = await alertService.firestoreService.updateUserLocation(userId, locationData);
    
    res.json({
      success: true,
      data: result,
      message: 'Location updated successfully'
    });
  } catch (error) {
    console.error('Location update error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Update user preferences endpoint
app.put('/api/users/:userId/preferences', async (req, res) => {
  try {
    const { userId } = req.params;
    const preferences = req.body;
    
    const result = await alertService.firestoreService.updateUserPreferences(userId, preferences);
    
    res.json({
      success: true,
      data: result,
      message: 'Preferences updated successfully'
    });
  } catch (error) {
    console.error('Preferences update error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get user data endpoint
app.get('/api/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const userData = await alertService.firestoreService.getUser(userId);
    
    if (!userData) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get nearby alerts for a user
app.get('/api/users/:userId/alerts/nearby', async (req, res) => {
  try {
    const { userId } = req.params;
    const { radius = 50 } = req.query;
    
    const userData = await alertService.firestoreService.getUser(userId);
    if (!userData || !userData.location) {
      return res.status(400).json({
        success: false,
        error: 'User location not available'
      });
    }
    
    const nearbyAlerts = await alertService.getNearbyAlerts(
      userData.location.latitude,
      userData.location.longitude,
      parseFloat(radius)
    );
    
    res.json({
      success: true,
      data: nearbyAlerts
    });
  } catch (error) {
    console.error('Get nearby alerts error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Update user FCM token endpoint
app.put('/api/users/:userId/fcm-token', async (req, res) => {
  try {
    const { userId } = req.params;
    const { fcmToken } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required'
      });
    }
    
    const { db } = require('./config/firebase');
    const userRef = db.collection('users').doc(userId);
    await userRef.update({
      fcmToken: fcmToken,
      lastActiveAt: new Date().toISOString()
    });
    
    res.json({
      success: true,
      message: 'FCM token updated successfully'
    });
  } catch (error) {
    console.error('FCM token update error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Scheduled location update (every 5 minutes)
setInterval(async () => {
  console.log('Running scheduled user location cleanup...');
  try {
    // This could be expanded to clean up old location data, 
    // remove inactive users, etc.
    // For now, it's just a placeholder for future location-based cleanup tasks
  } catch (error) {
    console.error('Scheduled location cleanup error:', error);
  }
}, 5 * 60 * 1000); // 5 minutes

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Start server
app.listen(port, async () => {
  console.log(`🚀 AlertFlow API server running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`📋 Active alerts: http://localhost:${port}/api/alerts`);
  console.log(`🔧 Manual scraping: POST http://localhost:${port}/api/scrape`);
  
  // Run initial scraping if environment variable is set
  if (process.env.ENABLE_AUTO_SCRAPE === 'true') {
    console.log('🔍 Auto-scraping enabled - running initial scrape...');
    try {
      await runScraping();
      console.log('✅ Initial scraping completed');
    } catch (error) {
      console.error('❌ Initial scraping failed:', error.message);
    }
  } else {
    console.log('ℹ️  Auto-scraping disabled. Use POST /api/scrape to trigger manually');
  }
});

module.exports = app;
