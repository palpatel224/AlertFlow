const { messaging } = require('../config/firebase');

/**
 * Firebase Cloud Messaging service for sending push notifications
 */
class FCMService {
  constructor() {
    this.maxTokensPerBatch = 500; // FCM limit for multicast
  }

  /**
   * Send notification to a single device
   * @param {string} token - FCM token
   * @param {Object} alert - Alert data
   * @returns {Promise<Object>} Response from FCM
   */
  async sendToDevice(token, alert) {
    try {
      const message = this.buildMessage(alert, token);
      const response = await messaging.send(message);
      console.log(`Notification sent successfully to device: ${response}`);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('Error sending notification to device:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notifications to multiple devices using multicast
   * @param {Array} tokens - Array of FCM tokens
   * @param {Object} alert - Alert data
   * @returns {Promise<Object>} Batch response from FCM
   */
  async sendToMultipleDevices(tokens, alert) {
    try {
      const responses = [];
      
      // Process tokens in batches to respect FCM limits
      for (let i = 0; i < tokens.length; i += this.maxTokensPerBatch) {
        const batch = tokens.slice(i, i + this.maxTokensPerBatch);
        const batchTokens = batch.map(tokenObj => 
          typeof tokenObj === 'string' ? tokenObj : tokenObj.token
        );

        const message = this.buildMulticastMessage(alert, batchTokens);
        const response = await messaging.sendMulticast(message);
        
        responses.push({
          batchIndex: Math.floor(i / this.maxTokensPerBatch),
          successCount: response.successCount,
          failureCount: response.failureCount,
          responses: response.responses
        });

        // Handle failed tokens
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, index) => {
            if (!resp.success) {
              failedTokens.push({
                token: batchTokens[index],
                error: resp.error?.message
              });
            }
          });
          console.warn(`Failed to send to ${failedTokens.length} tokens:`, failedTokens);
        }

        console.log(`Batch ${Math.floor(i / this.maxTokensPerBatch)}: ${response.successCount}/${batchTokens.length} notifications sent`);
      }

      const totalSuccess = responses.reduce((sum, batch) => sum + batch.successCount, 0);
      const totalFailure = responses.reduce((sum, batch) => sum + batch.failureCount, 0);

      return {
        success: true,
        totalSent: totalSuccess,
        totalFailed: totalFailure,
        batchResponses: responses
      };
    } catch (error) {
      console.error('Error sending multicast notifications:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notifications based on user preferences
   * @param {Array} userTokens - Array of user token objects with preferences
   * @param {Object} alert - Alert data
   * @returns {Promise<Object>} Response from sending notifications
   */
  async sendToTargetedUsers(userTokens, alert) {
    try {
      // Filter users based on alert type and severity preferences
      const targetedUsers = userTokens.filter(user => {
        const prefs = user.preferences || {};
        
        // Check disaster type preference
        const allowedTypes = prefs.disasterTypes || [];
        const typeMatch = allowedTypes.length === 0 || 
          allowedTypes.includes(alert.disasterType?.toLowerCase());
        
        // Check severity preference
        const allowedSeverities = prefs.severityLevels || [];
        const severityMatch = allowedSeverities.length === 0 || 
          allowedSeverities.includes(alert.severity);
        
        return typeMatch && severityMatch;
      });

      console.log(`Targeting ${targetedUsers.length} users out of ${userTokens.length} total users`);

      if (targetedUsers.length === 0) {
        return { success: true, totalSent: 0, message: 'No users match notification preferences' };
      }

      const tokens = targetedUsers.map(user => user.token);
      return await this.sendToMultipleDevices(tokens, alert);
    } catch (error) {
      console.error('Error sending targeted notifications:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notification to a topic
   * @param {string} topic - Topic name
   * @param {Object} alert - Alert data
   * @returns {Promise<Object>} Response from FCM
   */
  async sendToTopic(topic, alert) {
    try {
      const message = this.buildTopicMessage(alert, topic);
      const response = await messaging.send(message);
      console.log(`Notification sent to topic ${topic}: ${response}`);
      return { success: true, messageId: response };
    } catch (error) {
      console.error(`Error sending notification to topic ${topic}:`, error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Build FCM message for single device
   * @param {Object} alert - Alert data
   * @param {string} token - FCM token
   * @returns {Object} FCM message object
   */
  buildMessage(alert, token) {
    return {
      token,
      notification: {
        title: this.getNotificationTitle(alert),
        body: this.getNotificationBody(alert)
      },
      data: {
        alertId: alert.id,
        disasterType: alert.disasterType,
        severity: alert.severity,
        location: alert.location,
        magnitude: alert.magnitude.toString(),
        latitude: alert.latitude?.toString() || '',
        longitude: alert.longitude?.toString() || '',
        createdAt: alert.createdAt.toISOString(),
        clickAction: 'ALERT_DETAIL'
      },
      android: {
        notification: {
          icon: 'ic_alert',
          color: this.getSeverityColor(alert.severity),
          channelId: 'disaster_alerts',
          priority: this.getAndroidPriority(alert.severity),
          defaultSound: true,
          defaultVibrateTimings: true
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: this.getNotificationTitle(alert),
              body: this.getNotificationBody(alert)
            },
            sound: 'default',
            badge: 1,
            category: 'DISASTER_ALERT'
          }
        }
      }
    };
  }

  /**
   * Build FCM message for multiple devices
   * @param {Object} alert - Alert data
   * @param {Array} tokens - Array of FCM tokens
   * @returns {Object} FCM multicast message object
   */
  buildMulticastMessage(alert, tokens) {
    const baseMessage = this.buildMessage(alert, null);
    delete baseMessage.token;
    return {
      ...baseMessage,
      tokens
    };
  }

  /**
   * Build FCM message for topic
   * @param {Object} alert - Alert data
   * @param {string} topic - Topic name
   * @returns {Object} FCM topic message object
   */
  buildTopicMessage(alert, topic) {
    const baseMessage = this.buildMessage(alert, null);
    delete baseMessage.token;
    return {
      ...baseMessage,
      topic
    };
  }

  /**
   * Generate notification title based on alert
   * @param {Object} alert - Alert data
   * @returns {string} Notification title
   */
  getNotificationTitle(alert) {
    const severityEmoji = {
      low: '🟡',
      medium: '🟠',
      high: '🔴',
      critical: '🚨'
    };

    const emoji = severityEmoji[alert.severity] || '⚠️';
    return `${emoji} ${alert.disasterType.toUpperCase()} Alert`;
  }

  /**
   * Generate notification body based on alert
   * @param {Object} alert - Alert data
   * @returns {string} Notification body
   */
  getNotificationBody(alert) {
    let body = `${alert.disasterType} detected in ${alert.location}`;
    
    if (alert.magnitude && alert.magnitude !== 'Unknown') {
      body += ` (Magnitude: ${alert.magnitude})`;
    }
    
    return body + '. Tap for details.';
  }

  /**
   * Get color based on severity level
   * @param {string} severity - Severity level
   * @returns {string} Color code
   */
  getSeverityColor(severity) {
    const colors = {
      low: '#FFA500',    // Orange
      medium: '#FF6B35', // Red-Orange
      high: '#FF0000',   // Red
      critical: '#8B0000' // Dark Red
    };
    return colors[severity] || '#FFA500';
  }

  /**
   * Get Android notification priority based on severity
   * @param {string} severity - Severity level
   * @returns {string} Android priority
   */
  getAndroidPriority(severity) {
    const priorities = {
      low: 'normal',
      medium: 'high',
      high: 'high',
      critical: 'max'
    };
    return priorities[severity] || 'normal';
  }

  /**
   * Clean up invalid FCM tokens
   * @param {Array} invalidTokens - Array of invalid tokens
   * @returns {Promise<void>}
   */
  async cleanupInvalidTokens(invalidTokens) {
    try {
      // This would typically involve removing tokens from your user database
      console.log(`Cleaning up ${invalidTokens.length} invalid tokens`);
      // Implementation depends on your user management system
    } catch (error) {
      console.error('Error cleaning up invalid tokens:', error);
    }
  }
}

module.exports = FCMService;
