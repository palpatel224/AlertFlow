const axios = require('axios');
const dotenv = require('dotenv');
const AlertService = require('./services/alertService');

dotenv.config();

const alertService = new AlertService();

async function queryGemini(aggregatedText) {
  const prompt = `
  You are given disaster/earthquake information from official sources.
  
  Please extract and return a JSON array with each disaster as a separate object:
  - Disaster Type (e.g., earthquake, cyclone, flood)
  - Latitude and Longitude (numeric values)
  - Location or state affected
  - Date and time of occurrence
  - Magnitude of the disaster
  
  Respond ONLY in this JSON array format:
  [
    {
      "disasterType": "earthquake",
      "latitude": "37.7749",
      "longitude": "-122.4194",
      "location": "San Francisco, CA",
      "date": "2025-06-04",
      "time": "14:30:00",
      "magnitude": "5.2"
    }
  ]

  Here is the data:
  """
  ${aggregatedText}
  """`;

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        contents: [{ parts: [{ text: prompt }] }],
      },
      { headers: { "Content-Type": "application/json" } }
    );

    const result = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
    console.log("\n🤖 Gemini Response:\n", result);
    
    // Process the alerts through the complete pipeline
    const processingResults = await alertService.processAlerts(result);
    
    if (processingResults.success) {
      console.log("\n🎉 Alert processing completed successfully!");
      console.log(`📊 Summary: ${processingResults.processed.valid} alerts stored, ${processingResults.processed.notificationsSent} notifications sent`);
    } else {
      console.error("\n❌ Alert processing failed:", processingResults.error);
    }
    
    return result;
  } catch (error) {
    console.error('💥 Error in Gemini query or alert processing:', error);
    throw error;
  }
}

module.exports = { queryGemini };