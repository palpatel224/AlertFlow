const axios = require('axios');
const dotenv = require('dotenv');

dotenv.config();



async function queryGemini(aggregatedText) {
  const prompt = `
  You are given weather/disaster information from IMD's official website.
  
  Please extract and return:
  - Disaster Type (e.g., cyclone, flood)
  - Latitude and Longitude 
  - Location or state affected
  - date and time of occurrence
  - Magnitude of the disaster
  
  Respond ONLY in this JSON format for all 5 earthquakes:
  {
    "disasterType": "...",
    "latitude": "...",
    "longitude": "...",
    "location": "...",
    "date": "...",
    "time": "...",
    "magnitude": "..."
  }

  Here is the data:
  """
  ${aggregatedText}
  """`;

  const response = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
    {
      contents: [{ parts: [{ text: prompt }] }],
    },
    { headers: { "Content-Type": "application/json" } }
  );

  const result = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
  console.log("\n Gemini Response:\n", result);
  return result;
}

module.exports = { queryGemini };