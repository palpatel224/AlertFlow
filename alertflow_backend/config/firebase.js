// Firebase Admin SDK configuration
const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

// Initialize Firebase Admin SDK
let app;
let db;
let messaging;
let isDemo = false;

try {
  let serviceAccount;
  
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      
      // Fix private key formatting - replace escaped newlines with actual newlines
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
      }
      
      console.log('✅ Firebase service account loaded from environment');
    } catch (parseError) {
      console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT_KEY:', parseError.message);
      throw parseError;
    }
  } else {
    try {
      serviceAccount = require('./serviceAccountKey.json');
      console.log('✅ Firebase service account loaded from file');
    } catch (err) {
      console.log('⚠️  No Firebase credentials found. Running in demo mode.');
      console.log('   To enable Firebase: Add FIREBASE_SERVICE_ACCOUNT_KEY to .env or create serviceAccountKey.json');
      isDemo = true;
    }
  }
  
  if (isDemo) {
    // Create a mock app for demo purposes
    app = {
      firestore: () => ({
        collection: () => ({
          add: () => Promise.resolve({ id: 'demo_' + Date.now() }),
          doc: () => ({
            set: () => Promise.resolve(),
            get: () => Promise.resolve({ exists: false }),
            delete: () => Promise.resolve()
          }),
          where: () => ({
            get: () => Promise.resolve({ docs: [] })
          })
        })
      }),
      messaging: () => ({
        send: () => Promise.resolve('demo_message_id'),
        sendMulticast: () => Promise.resolve({ successCount: 0, failureCount: 0 })
      })
    };
    
    db = app.firestore();
    messaging = app.messaging();
  } else {
    // Initialize Firebase Admin
    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
      // Note: databaseURL is only needed for Realtime Database, not Firestore
    });
    
    db = admin.firestore();
    messaging = admin.messaging();
    
    // Configure Firestore settings
    db.settings({
      timestampsInSnapshots: true
    });
    
    console.log('✅ Firebase Admin SDK initialized successfully');
    console.log(`📍 Project ID: ${serviceAccount.project_id}`);
    console.log(`� Using Firestore (NoSQL Document Database)`);
  }
    } catch (error) {
  console.error('❌ Error initializing Firebase:', error);
  throw error;
}

// Test Firebase connection
async function testFirebaseConnection() {
  if (isDemo) {
    console.log('🧪 Running in demo mode - Firebase connection not tested');
    return true;
  }
  
  try {
    // Test Firestore connection
    await db.collection('_test').limit(1).get();
    console.log('✅ Firestore connection successful');
    
    // Test if we can write (optional)
    const testRef = db.collection('_test').doc('connection_test');
    await testRef.set({ timestamp: admin.firestore.FieldValue.serverTimestamp() });
    await testRef.delete();
    console.log('✅ Firestore write/delete permissions confirmed');
    
    return true;
  } catch (error) {
    console.error('❌ Firebase connection test failed:', error.message);
    return false;
  }
}

module.exports = {
  admin,
  db,
  messaging,
  isDemo,
  testFirebaseConnection
};
