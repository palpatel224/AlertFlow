const { db } = require('../config/firebase');

/**
 * Firestore service for managing disaster alerts
 */
class FirestoreService {
  constructor() {
    this.alertsCollection = 'alerts';
    this.usersCollection = 'users';
  }

  /**
   * Store a single alert in Firestore with TTL
   * @param {Object} alert - Formatted alert object
   * @returns {Promise<string>} Document ID of the stored alert
   */
  async storeAlert(alert) {
    try {
      const docRef = await db.collection(this.alertsCollection).add(alert);
      console.log(`Alert stored with ID: ${docRef.id}`);
      return docRef.id;
    } catch (error) {
      console.error('Error storing alert:', error);
      throw new Error('Failed to store alert in Firestore');
    }
  }

  /**
   * Store multiple alerts in Firestore using batch write
   * @param {Array} alerts - Array of formatted alert objects
   * @returns {Promise<Array>} Array of document IDs
   */
  async storeMultipleAlerts(alerts) {
    try {
      const batch = db.batch();
      const docIds = [];

      alerts.forEach(alert => {
        const docRef = db.collection(this.alertsCollection).doc();
        batch.set(docRef, alert);
        docIds.push(docRef.id);
      });

      await batch.commit();
      console.log(`${alerts.length} alerts stored successfully`);
      return docIds;
    } catch (error) {
      console.error('Error storing multiple alerts:', error);
      throw new Error('Failed to store alerts in Firestore');
    }
  }

  /**
   * Get active alerts from Firestore
   * @param {number} limit - Maximum number of alerts to retrieve
   * @returns {Promise<Array>} Array of active alerts
   */
  async getActiveAlerts(limit = 50) {
    try {
      const snapshot = await db.collection(this.alertsCollection)
        .where('isActive', '==', true)
        .where('expiresAt', '>', new Date())
        .orderBy('expiresAt', 'desc')
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const alerts = [];
      snapshot.forEach(doc => {
        alerts.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return alerts;
    } catch (error) {
      console.error('Error retrieving active alerts:', error);
      throw new Error('Failed to retrieve alerts from Firestore');
    }
  }

  /**
   * Get alerts by severity level
   * @param {string} severity - Severity level to filter by
   * @param {number} limit - Maximum number of alerts to retrieve
   * @returns {Promise<Array>} Array of alerts with specified severity
   */
  async getAlertsBySeverity(severity, limit = 20) {
    try {
      const snapshot = await db.collection(this.alertsCollection)
        .where('isActive', '==', true)
        .where('severity', '==', severity)
        .where('expiresAt', '>', new Date())
        .orderBy('expiresAt', 'desc')
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const alerts = [];
      snapshot.forEach(doc => {
        alerts.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return alerts;
    } catch (error) {
      console.error('Error retrieving alerts by severity:', error);
      throw new Error('Failed to retrieve alerts by severity');
    }
  }

  /**
   * Update alert notification status
   * @param {string} alertId - ID of the alert to update
   * @param {boolean} notificationSent - Whether notification was sent
   * @returns {Promise<void>}
   */
  async updateNotificationStatus(alertId, notificationSent = true) {
    try {
      await db.collection(this.alertsCollection).doc(alertId).update({
        notificationSent,
        notificationSentAt: new Date()
      });
      console.log(`Alert ${alertId} notification status updated`);
    } catch (error) {
      console.error('Error updating notification status:', error);
      throw new Error('Failed to update notification status');
    }
  }

  /**
   * Deactivate expired alerts (manual cleanup if TTL isn't working)
   * @returns {Promise<number>} Number of alerts deactivated
   */
  async deactivateExpiredAlerts() {
    try {
      const snapshot = await db.collection(this.alertsCollection)
        .where('isActive', '==', true)
        .where('expiresAt', '<=', new Date())
        .get();

      const batch = db.batch();
      let count = 0;

      snapshot.forEach(doc => {
        batch.update(doc.ref, { isActive: false });
        count++;
      });

      if (count > 0) {
        await batch.commit();
        console.log(`Deactivated ${count} expired alerts`);
      }

      return count;
    } catch (error) {
      console.error('Error deactivating expired alerts:', error);
      throw new Error('Failed to deactivate expired alerts');
    }
  }

  /**
   * Get all user FCM tokens for push notifications
   * @param {Array} userPreferences - Optional filter by user preferences
   * @returns {Promise<Array>} Array of FCM tokens
   */
  async getUserFCMTokens(userPreferences = null) {
    try {
      let query = db.collection(this.usersCollection)
        .where('fcmToken', '!=', null)
        .where('notificationsEnabled', '==', true);

      // Add preference filters if provided
      if (userPreferences && userPreferences.length > 0) {
        query = query.where('preferences.disasterTypes', 'array-contains-any', userPreferences);
      }

      const snapshot = await query.get();
      const tokens = [];

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.fcmToken) {
          tokens.push({
            token: data.fcmToken,
            userId: doc.id,
            preferences: data.preferences || {}
          });
        }
      });

      console.log(`Retrieved ${tokens.length} FCM tokens`);
      return tokens;
    } catch (error) {
      console.error('Error retrieving FCM tokens:', error);
      throw new Error('Failed to retrieve FCM tokens');
    }
  }

  /**
   * Store user FCM token (for testing purposes)
   * @param {string} userId - User ID
   * @param {string} fcmToken - FCM token
   * @param {Object} preferences - User notification preferences
   * @returns {Promise<void>}
   */
  async storeUserToken(userId, fcmToken, preferences = {}) {
    try {
      await db.collection(this.usersCollection).doc(userId).set({
        fcmToken,
        notificationsEnabled: true,
        preferences: {
          disasterTypes: preferences.disasterTypes || ['earthquake', 'cyclone', 'flood'],
          severityLevels: preferences.severityLevels || ['medium', 'high', 'critical'],
          ...preferences
        },
        updatedAt: new Date()
      }, { merge: true });

      console.log(`User token stored for ${userId}`);
    } catch (error) {
      console.error('Error storing user token:', error);
      throw new Error('Failed to store user token');
    }
  }

  /**
   * Save complete user data (upsert operation)
   * @param {Object} userData - Complete user data object
   * @returns {Promise<Object>} Saved user data
   */
  async saveUser(userData) {
    try {
      const userRef = db.collection(this.usersCollection).doc(userData.userId);
      
      // Check if user exists
      const existingUser = await userRef.get();
      
      if (existingUser.exists) {
        // Update existing user - merge with existing data
        const existingData = existingUser.data();
        const mergedData = {
          ...existingData,
          ...userData,
          lastActiveAt: new Date().toISOString(),
          // Only update location if new data has valid coordinates
          location: (userData.location && userData.location.latitude && userData.location.longitude) 
            ? userData.location 
            : existingData.location || null,
          // Only update FCM token if provided
          fcmToken: userData.fcmToken || existingData.fcmToken || null
        };
        
        await userRef.set(mergedData, { merge: true });
        console.log(`User data updated for ${userData.userId}`);
        return mergedData;
      } else {
        // Create new user with proper validation
        const newUserData = {
          userId: userData.userId,
          fcmToken: userData.fcmToken || null,
          location: {
            latitude: userData.location?.latitude || null,
            longitude: userData.location?.longitude || null,
            lastUpdated: new Date().toISOString()
          },
          preferences: userData.preferences || {
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
        
        await userRef.set(newUserData);
        console.log(`New user created: ${userData.userId}`);
        return newUserData;
      }
    } catch (error) {
      console.error('Error saving user data:', error);
      throw new Error('Failed to save user data');
    }
  }

  /**
   * Get user data by ID
   * @param {string} userId - User identifier
   * @returns {Promise<Object|null>} User data or null if not found
   */
  async getUser(userId) {
    try {
      const userDoc = await db.collection(this.usersCollection).doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      return {
        id: userDoc.id,
        ...userDoc.data()
      };
    } catch (error) {
      console.error('Error getting user data:', error);
      throw new Error('Failed to get user data');
    }
  }

  /**
   * Update user location (ensures single user entry)
   * @param {string} userId - User identifier
   * @param {Object} locationData - Location data with latitude, longitude, lastUpdated
   * @returns {Promise<Object>} Updated location data
   */
  async updateUserLocation(userId, locationData) {
    try {
      const userRef = db.collection(this.usersCollection).doc(userId);
      
      // Validate location data
      if (!locationData.latitude || !locationData.longitude) {
        throw new Error('Invalid location data: latitude and longitude are required');
      }
      
      const updateData = {
        'location.latitude': locationData.latitude,
        'location.longitude': locationData.longitude,
        'location.lastUpdated': locationData.lastUpdated || new Date().toISOString(),
        lastActiveAt: new Date().toISOString()
      };
      
      await userRef.update(updateData);
      
      console.log(`Location updated for user ${userId}: ${locationData.latitude}, ${locationData.longitude}`);
      return locationData;
    } catch (error) {
      console.error('Error updating user location:', error);
      throw new Error('Failed to update user location');
    }
  }

  /**
   * Update user preferences
   * @param {string} userId - User identifier
   * @param {Object} preferences - User preferences object
   * @returns {Promise<Object>} Updated preferences
   */
  async updateUserPreferences(userId, preferences) {
    try {
      const userRef = db.collection(this.usersCollection).doc(userId);
      await userRef.update({
        preferences: preferences,
        lastActiveAt: new Date().toISOString()
      });
      
      console.log(`Preferences updated for user ${userId}`);
      return preferences;
    } catch (error) {
      console.error('Error updating user preferences:', error);
      throw new Error('Failed to update user preferences');
    }
  }

  /**
   * Get all users within a geographic radius
   * @param {number} centerLat - Center latitude
   * @param {number} centerLng - Center longitude
   * @param {number} radiusKm - Radius in kilometers
   * @returns {Promise<Array>} Array of users within radius
   */
  async getUsersInRadius(centerLat, centerLng, radiusKm) {
    try {
      // Note: This is a simplified implementation
      // For production, consider using geohash or specialized geo-queries
      const snapshot = await db.collection(this.usersCollection)
        .where('location.latitude', '!=', null)
        .get();

      const users = [];
      snapshot.forEach(doc => {
        const userData = doc.data();
        if (userData.location && userData.location.latitude && userData.location.longitude) {
          const distance = this.calculateDistance(
            centerLat, centerLng,
            userData.location.latitude, userData.location.longitude
          );
          
          if (distance <= radiusKm) {
            users.push({
              id: doc.id,
              ...userData,
              distanceKm: distance
            });
          }
        }
      });

      return users;
    } catch (error) {
      console.error('Error getting users in radius:', error);
      throw new Error('Failed to get users in radius');
    }
  }

  /**
   * Calculate distance between two points using Haversine formula
   * @param {number} lat1 - First point latitude
   * @param {number} lng1 - First point longitude
   * @param {number} lat2 - Second point latitude
   * @param {number} lng2 - Second point longitude
   * @returns {number} Distance in kilometers
   */
  calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.toRadians(lat2 - lat1);
    const dLng = this.toRadians(lng2 - lng1);
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Convert degrees to radians
   * @param {number} degrees - Degrees to convert
   * @returns {number} Radians
   */
  toRadians(degrees) {
    return degrees * (Math.PI / 180);
  }
}

module.exports = FirestoreService;
