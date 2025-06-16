const { v4: uuidv4 } = require('uuid');

/**
 * Formats Gemini response into structured alert JSON
 * @param {string} geminiResponse - Raw response from Gemini API
 * @returns {Array} Array of formatted alert objects
 */
function formatAlertsFromGemini(geminiResponse) {
  try {
    // Clean the response - remove any markdown formatting or extra text
    let cleanResponse = geminiResponse.trim();
    
    // Remove markdown code blocks if present
    cleanResponse = cleanResponse.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    
    // Handle case where Gemini returns multiple JSON objects
    const alerts = [];
    
    // Try to parse as single JSON first
    try {
      const parsed = JSON.parse(cleanResponse);
      if (Array.isArray(parsed)) {
        alerts.push(...parsed);
      } else {
        alerts.push(parsed);
      }
    } catch (singleParseError) {
      // If single parse fails, try to extract multiple JSON objects
      const jsonMatches = cleanResponse.match(/\{[^{}]*\}/g);
      if (jsonMatches) {
        jsonMatches.forEach(match => {
          try {
            const parsed = JSON.parse(match);
            alerts.push(parsed);
          } catch (error) {
            console.warn('Failed to parse individual JSON object:', match);
          }
        });
      }
    }

    // Format each alert with required fields
    const formattedAlerts = alerts.map(alert => {
      const now = new Date();
      const expirationTime = new Date(now.getTime() + (24 * 60 * 60 * 1000)); // 24 hours from now

      return {
        id: uuidv4(),
        disasterType: alert.disasterType || 'Unknown',
        latitude: parseFloat(alert.latitude) || null,
        longitude: parseFloat(alert.longitude) || null,
        location: alert.location || 'Unknown Location',
        date: alert.date || now.toISOString().split('T')[0],
        time: alert.time || now.toTimeString().split(' ')[0],
        magnitude: alert.magnitude || 'Unknown',
        severity: determineSeverity(alert.magnitude, alert.disasterType),
        createdAt: now,
        expiresAt: expirationTime,
        isActive: true,
        source: 'USGS',
        notificationSent: false
      };
    });

    return formattedAlerts;
  } catch (error) {
    console.error('Error formatting alerts from Gemini response:', error);
    throw new Error('Failed to format alert data');
  }
}

/**
 * Determines severity level based on magnitude and disaster type
 * @param {string} magnitude - Magnitude of the disaster
 * @param {string} disasterType - Type of disaster
 * @returns {string} Severity level: 'low', 'medium', 'high', 'critical'
 */
function determineSeverity(magnitude, disasterType) {
  const mag = parseFloat(magnitude);
  
  if (isNaN(mag)) return 'medium';
  
  switch (disasterType?.toLowerCase()) {
    case 'earthquake':
      if (mag >= 7.0) return 'critical';
      if (mag >= 6.0) return 'high';
      if (mag >= 4.0) return 'medium';
      return 'low';
    
    case 'cyclone':
    case 'hurricane':
      if (mag >= 4) return 'critical';
      if (mag >= 3) return 'high';
      if (mag >= 2) return 'medium';
      return 'low';
    
    default:
      if (mag >= 7.0) return 'critical';
      if (mag >= 5.0) return 'high';
      if (mag >= 3.0) return 'medium';
      return 'low';
  }
}

/**
 * Validates alert data structure
 * @param {Object} alert - Alert object to validate
 * @returns {boolean} True if valid, false otherwise
 */
function validateAlert(alert) {
  const requiredFields = ['id', 'disasterType', 'location', 'createdAt', 'expiresAt'];
  
  for (const field of requiredFields) {
    if (!alert[field]) {
      console.warn(`Alert missing required field: ${field}`);
      return false;
    }
  }
  
  // Validate coordinates if provided
  if (alert.latitude !== null && (alert.latitude < -90 || alert.latitude > 90)) {
    console.warn('Invalid latitude value');
    return false;
  }
  
  if (alert.longitude !== null && (alert.longitude < -180 || alert.longitude > 180)) {
    console.warn('Invalid longitude value');
    return false;
  }
  
  return true;
}

module.exports = {
  formatAlertsFromGemini,
  determineSeverity,
  validateAlert
};
