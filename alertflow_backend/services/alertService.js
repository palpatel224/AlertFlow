const FirestoreService = require('./firestoreService');
const FCMService = require('./fcmService');
const { formatAlertsFromGemini, validateAlert } = require('./alertFormatter');

/**
 * Main alert processing service
 * Coordinates the entire pipeline
 */
class AlertService {
  constructor() {
    this.firestoreService = new FirestoreService();
    this.fcmService = new FCMService();
  }

  /**
   * Process alerts from Gemini response and handle the complete workflow
   * @param {string} geminiResponse - Raw response from Gemini API
   * @returns {Promise<Object>} Processing results
   */
  async processAlerts(geminiResponse) {
    try {
      console.log('🔄 Starting alert processing...');
      
      // Step 1: Format alerts from Gemini response
      const formattedAlerts = formatAlertsFromGemini(geminiResponse);
      console.log(`📋 Formatted ${formattedAlerts.length} alerts`);

      // Step 2: Validate alerts
      const validAlerts = formattedAlerts.filter(alert => {
        const isValid = validateAlert(alert);
        if (!isValid) {
          console.warn(`❌ Invalid alert skipped: ${alert.id}`);
        }
        return isValid;
      });

      if (validAlerts.length === 0) {
        console.warn('⚠️ No valid alerts to process');
        return { success: false, message: 'No valid alerts found' };
      }

      console.log(`✅ ${validAlerts.length} valid alerts ready for processing`);

      // Step 3: Store alerts in Firestore
      const storedDocIds = await this.firestoreService.storeMultipleAlerts(validAlerts);
      console.log(`💾 Stored ${storedDocIds.length} alerts in Firestore`);

      // Step 4: Send push notifications
      const notificationResults = await this.sendNotificationsForAlerts(validAlerts);

      // Step 5: Update notification status for successfully sent alerts
      await this.updateNotificationStatuses(validAlerts, notificationResults);

      // Step 6: Cleanup expired alerts (optional maintenance)
      const cleanupCount = await this.firestoreService.deactivateExpiredAlerts();
      if (cleanupCount > 0) {
        console.log(`🧹 Cleaned up ${cleanupCount} expired alerts`);
      }

      const results = {
        success: true,
        processed: {
          total: formattedAlerts.length,
          valid: validAlerts.length,
          stored: storedDocIds.length,
          notificationsSent: notificationResults.totalSent || 0,
          notificationsFailed: notificationResults.totalFailed || 0
        },
        alerts: validAlerts.map(alert => ({
          id: alert.id,
          type: alert.disasterType,
          location: alert.location,
          severity: alert.severity
        }))
      };

      console.log('🎉 Alert processing completed successfully:', results.processed);
      return results;

    } catch (error) {
      console.error('💥 Error processing alerts:', error);
      return {
        success: false,
        error: error.message,
        processed: { total: 0, valid: 0, stored: 0 }
      };
    }
  }

  /**
   * Send notifications for new alerts
   * @param {Array} alerts - Array of alert objects
   * @returns {Promise<Object>} Notification results
   */
  async sendNotificationsForAlerts(alerts) {
    try {
      console.log('📱 Starting notification sending process...');

      // Get user FCM tokens
      const userTokens = await this.firestoreService.getUserFCMTokens();
      
      if (userTokens.length === 0) {
        console.warn('⚠️ No user tokens found for notifications');
        return { totalSent: 0, totalFailed: 0 };
      }

      let totalSent = 0;
      let totalFailed = 0;

      // Send notifications for each alert
      for (const alert of alerts) {
        console.log(`📤 Sending notifications for ${alert.disasterType} alert in ${alert.location}`);
        
        const result = await this.fcmService.sendToTargetedUsers(userTokens, alert);
        
        if (result.success) {
          totalSent += result.totalSent || 0;
          totalFailed += result.totalFailed || 0;
          
          // Also send to topic for high/critical severity alerts
          if (['high', 'critical'].includes(alert.severity)) {
            await this.fcmService.sendToTopic(`alerts_${alert.severity}`, alert);
            console.log(`📡 Sent ${alert.severity} alert to topic`);
          }
        } else {
          console.error(`❌ Failed to send notifications for alert ${alert.id}:`, result.error);
          totalFailed += userTokens.length;
        }
      }

      console.log(`📊 Notification summary: ${totalSent} sent, ${totalFailed} failed`);
      return { totalSent, totalFailed };

    } catch (error) {
      console.error('💥 Error sending notifications:', error);
      throw error;
    }
  }

  /**
   * Update notification status for alerts after sending
   * @param {Array} alerts - Array of alert objects
   * @param {Object} notificationResults - Results from notification sending
   * @returns {Promise<void>}
   */
  async updateNotificationStatuses(alerts, notificationResults) {
    try {
      const notificationSent = notificationResults.totalSent > 0;
      
      for (const alert of alerts) {
        await this.firestoreService.updateNotificationStatus(alert.id, notificationSent);
      }
      
      console.log(`📝 Updated notification status for ${alerts.length} alerts`);
    } catch (error) {
      console.error('❌ Error updating notification statuses:', error);
      // Don't throw here as this is not critical for the main flow
    }
  }

  /**
   * Get active alerts (for API endpoints)
   * @param {Object} filters - Optional filters
   * @returns {Promise<Array>} Array of active alerts
   */
  async getActiveAlerts(filters = {}) {
    try {
      const { severity, limit = 50 } = filters;
      
      if (severity) {
        return await this.firestoreService.getAlertsBySeverity(severity, limit);
      } else {
        return await this.firestoreService.getActiveAlerts(limit);
      }
    } catch (error) {
      console.error('Error retrieving active alerts:', error);
      throw error;
    }
  }

  /**
   * Test notification system
   * @param {string} testToken - Test FCM token
   * @returns {Promise<Object>} Test results
   */
  async testNotificationSystem(testToken) {
    try {
      console.log('🧪 Testing notification system...');
      
      const testAlert = {
        id: 'test-alert-' + Date.now(),
        disasterType: 'Test Alert',
        location: 'Test Location',
        severity: 'medium',
        magnitude: '5.0',
        latitude: 37.7749,
        longitude: -122.4194,
        createdAt: new Date()
      };

      const result = await this.fcmService.sendToDevice(testToken, testAlert);
      
      if (result.success) {
        console.log('✅ Test notification sent successfully');
        return { success: true, messageId: result.messageId };
      } else {
        console.error('❌ Test notification failed:', result.error);
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('💥 Error testing notification system:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Store a test user token (for development/testing)
   * @param {string} userId - User ID
   * @param {string} fcmToken - FCM token
   * @param {Object} preferences - User preferences
   * @returns {Promise<void>}
   */
  async storeTestUser(userId, fcmToken, preferences = {}) {
    try {
      await this.firestoreService.storeUserToken(userId, fcmToken, preferences);
      console.log(`✅ Test user ${userId} stored successfully`);
    } catch (error) {
      console.error('❌ Error storing test user:', error);
      throw error;
    }
  }

  /**
   * Get nearby alerts for a specific location
   * @param {number} latitude - User's latitude
   * @param {number} longitude - User's longitude
   * @param {number} radiusKm - Search radius in kilometers
   * @returns {Promise<Array>} Array of nearby alerts with distance
   */
  async getNearbyAlerts(latitude, longitude, radiusKm = 50) {
    try {
      // Get all active alerts
      const allAlerts = await this.firestoreService.getActiveAlerts();
      
      // Filter alerts within radius and add distance information
      const nearbyAlerts = allAlerts
        .map(alert => {
          const distance = this.firestoreService.calculateDistance(
            latitude, longitude,
            alert.location.latitude, alert.location.longitude
          );
          
          return {
            ...alert,
            distanceKm: distance
          };
        })
        .filter(alert => alert.distanceKm <= radiusKm)
        .sort((a, b) => a.distanceKm - b.distanceKm); // Sort by distance
      
            console.log(`📍 Found ${nearbyAlerts.length} alerts within ${radiusKm}km`);
      return nearbyAlerts;
    } catch (error) {
      console.error('❌ Error getting nearby alerts:', error);
      throw error;
    }
  }
}

module.exports = AlertService;
