// Import required modules
const admin = require("firebase-admin");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require('cors');
const multer = require('multer');
const { Storage } = require('@google-cloud/storage');
const fs = require('fs');
const path = require('path');
const natural = require('natural');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const FormData = require('form-data');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
const mongoose = require("mongoose");
require('dotenv').config();

// Global variable to track database connection status
let mongoConnected = false;

// Set ffmpeg path
ffmpeg.setFfmpegPath(ffmpegPath);

// Configure multer for file uploads
const upload = multer({ 
  storage: multer.diskStorage({
    destination: function (req, file, cb) {
      const dir = './uploads';
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      cb(null, dir);
    },
    filename: function (req, file, cb) {
      cb(null, `${Date.now()}-${file.originalname}`);
    }
  })
});

// Initialize Google Cloud Storage
const storage = new Storage({
  keyFilename: './serviceAccountKey.json'
});
const bucketName = 'bravespace-speech-files';

// Load environment variables
require('dotenv').config();

// Constants
const PORT = process.env.PORT || 3000;
const FIREBASE_CONFIG = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

// Whisper API configuration
const IS_SELF_HOSTED_WHISPER = process.env.IS_SELF_HOSTED_WHISPER === 'true';
// Use localhost for local development, whisper-server for Docker
const WHISPER_API_URL = process.env.WHISPER_API_URL || 'http://localhost:9000/asr';
const WHISPER_API_KEY = process.env.WHISPER_API_KEY || '';

console.log('Whisper API URL:', WHISPER_API_URL);
console.log('Is self-hosted Whisper:', IS_SELF_HOSTED_WHISPER);

const app = express();

// Middleware
app.use(bodyParser.json());
app.use(cors());

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const bucket = storage.bucket(bucketName);

// MongoDB connection with better error handling
mongoose
  .connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
    socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
  })
  .then(() => {
    console.log("✅ MongoDB connected");
    mongoConnected = true;
  })
  .catch((err) => {
    console.error("❌ MongoDB connection error:", err);
    console.log("⚠️ Server will continue with limited functionality");
    mongoConnected = false;
  });

// Function to check if MongoDB is connected
function isMongoConnected() {
  return mongoConnected && mongoose.connection.readyState === 1;
}

// Middleware to verify the ID token
function verifyToken(req, res, next) {
  const idToken = req.headers.authorization?.split('Bearer ')[1];
  
  if (!idToken) {
    return res.status(401).json({ error: "No token provided" });
  }

  admin.auth().verifyIdToken(idToken)
    .then(decodedToken => {
      req.user = decodedToken;
      next();
    })
    .catch(error => {
      res.status(401).json({ error: "Invalid token" });
    });
}

// Middleware to verify user role
function verifyRole(allowedRoles) {
  return async (req, res, next) => {
    try {
      const userId = req.user.uid;
      const userDoc = await db.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }
      
      const userData = userDoc.data();
      const userRole = userData.role || 'child'; // Default to child if no role is set
      
      if (Array.isArray(allowedRoles) && allowedRoles.includes(userRole)) {
        req.userRole = userRole;
        next();
      } else if (typeof allowedRoles === 'string' && allowedRoles === userRole) {
        req.userRole = userRole;
        next();
      } else {
        res.status(403).json({ error: "Access denied: Insufficient role permissions" });
      }
    } catch (error) {
      console.error("Role verification error:", error);
      res.status(500).json({ error: "Internal server error during role verification" });
    }
  };
}

// Upload VR video route (Developer uploads)
app.post("/upload/vr-video", upload.single("video"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });

  const blob = bucket.file(`vr_videos/${Date.now()}_${req.file.originalname}`);
  const blobStream = blob.createWriteStream({ resumable: false });

  blobStream.on("error", (err) => res.status(500).json({ error: err.message }));

  blobStream.on("finish", async () => {
    await blob.makePublic(); // Make the file publicly accessible
    res.json({ message: "VR video uploaded successfully", url: blob.publicUrl() });
  });

  blobStream.end(req.file.buffer);
});

// User Sign-Up (Create a new user with email and password)
app.post("/signup", async (req, res) => {
  const { uid, email, firstName, lastName, role } = req.body;

  if (!uid || !email || !firstName || !lastName) {
    return res.status(400).send({ error: "All fields are required!" });
  }

  // Default role to 'child' if not provided
  const userRole = role || 'child';
  
  try {
    await db.collection('users').doc(uid).set({
      firstName,
      lastName,
      email,
      role: userRole,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await createInitialUserData(uid);

    res.status(201).send({
      message: "User data created successfully!",
      uid: uid,
      fullName: `${firstName} ${lastName}`,
      role: userRole
    });
  } catch (error) {
    res.status(400).send({ error: error.message });
  }
});

// User Sign-In (Verify the user and return a token)
app.post("/signin", async (req, res) => {
  const { email } = req.body;

  try {
    const user = await admin.auth().getUserByEmail(email);
    const token = await admin.auth().createCustomToken(user.uid);
    res.send({ token });
  } catch (error) {
    res.status(400).send({ error: error.message });
  }
});

// Verify Token Endpoint
app.post("/verifyToken", async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: "No token provided" });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();

    res.json({
      uid: decodedToken.uid,
      email: decodedToken.email,
      userData: userDoc.data(),
      message: "Token verified successfully",
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

// Protected route example
app.get("/protected-route", verifyToken, (req, res) => {
  res.json({
    message: "This is a protected route",
    user: req.user,
  });
});

// Upload Avatar route (Developer uploads)
app.post("/upload/avatar", upload.single("avatar"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });

  const blob = bucket.file(`avatars/${Date.now()}_${req.file.originalname}`);
  const blobStream = blob.createWriteStream({ resumable: false });

  blobStream.on("error", (err) => res.status(500).json({ error: err.message }));

  blobStream.on("finish", async () => {
    await blob.makePublic();
    res.json({ message: "Avatar uploaded successfully", url: blob.publicUrl() });
  });

  blobStream.end(req.file.buffer);
});

// Test endpoint
app.get("/", (req, res) => {
  res.send("BraveSpace Backend is working!");
});

// Endpoint for Unity to send speech data
app.post("/session-data", verifyToken, async (req, res) => {
  const { transcript, stutterCount, pauses, pronunciationScore } = req.body;
  const userId = req.user.uid;

  if (!transcript) {
    return res.status(400).json({ error: "Transcript is required" });
  }

  try {
    const sessionRef = db.collection("user_sessions").doc();
    await sessionRef.set({
      userId,
      transcript,
      stutterCount: stutterCount || 0,
      pauses: pauses || 0,
      pronunciationScore: pronunciationScore || 0,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ message: "Session data stored successfully", sessionId: sessionRef.id });
  } catch (error) {
    console.error("Error saving session data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Fetch progress tracking data
app.get("/progress", verifyToken, async (req, res) => {
  const userId = req.user.uid;

  try {
    const sessionsSnapshot = await db.collection("user_sessions")
      .where("userId", "==", userId)
      .orderBy("timestamp", "desc")
      .get();

    if (sessionsSnapshot.empty) {
      return res.json({ progress: [], message: "No session data available" });
    }

    let progressData = [];
    sessionsSnapshot.forEach(doc => {
      progressData.push({ id: doc.id, ...doc.data() });
    });

    res.json({ progress: progressData });
  } catch (error) {
    console.error("Error fetching progress data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Save speech session endpoint
app.post("/speech-sessions", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  const { topic, speechText, metrics, duration, feedback } = req.body;

  if (!topic || !speechText || !metrics || !duration || !feedback) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const sessionRef = await db.collection("speech_sessions").add({
      userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      topic,
      speechText,
      metrics,
      duration,
      feedback
    });

    res.json({ 
      message: "Speech session saved successfully", 
      sessionId: sessionRef.id 
    });
  } catch (error) {
    console.error("Error saving speech session:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Get user's speech sessions
app.get("/speech-sessions", verifyToken, async (req, res) => {
  const userId = req.user.uid;

  try {
    const sessionsSnapshot = await db.collection("speech_sessions")
      .where("userId", "==", userId)
      .orderBy("timestamp", "desc")
      .get();

    const sessions = [];
    sessionsSnapshot.forEach(doc => {
      const data = doc.data();
      sessions.push({
        id: doc.id,
        ...data,
        timestamp: {
          _seconds: data.timestamp.seconds,
          _nanoseconds: data.timestamp.nanoseconds
        }
      });
    });

    res.json({ sessions });
  } catch (error) {
    console.error("Error fetching speech sessions:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Get user statistics
app.get("/user-stats", verifyToken, async (req, res) => {
  const userId = req.user.uid;

  try {
    const sessionsSnapshot = await db.collection("speech_sessions")
      .where("userId", "==", userId)
      .get();

    if (sessionsSnapshot.empty) {
      return res.json({
        totalSessions: 0,
        totalDuration: 0,
        averageScore: 0.0
      });
    }

    let totalDuration = 0;
    let totalScore = 0;
    const sessions = [];

    sessionsSnapshot.forEach(doc => {
      const session = doc.data();
      sessions.push(session);
      totalDuration += session.duration;
      const sessionAvg = Object.values(session.metrics).reduce((a, b) => a + b, 0) / Object.keys(session.metrics).length;
      totalScore += sessionAvg;
    });

    res.json({
      totalSessions: sessions.length,
      totalDuration: totalDuration,
      averageScore: totalScore / sessions.length
    });
  } catch (error) {
    console.error("Error fetching user stats:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Function to create initial user data
async function createInitialUserData(userId) {
  await createUserChallenges(userId);

  const sessionsRef = db.collection('sessions');
  const now = admin.firestore.Timestamp.now();

  await sessionsRef.add({
    userId: userId,
    title: 'Presentation Practice',
    duration: '1 Hour',
    startTime: admin.firestore.Timestamp.fromDate(
      new Date(now.toDate().getTime() + 2 * 60 * 60 * 1000)
    ),
  });

  await sessionsRef.add({
    userId: userId,
    title: 'Speaking Session',
    duration: '30 min',
    startTime: admin.firestore.Timestamp.fromDate(
      new Date(now.toDate().getTime() + 4 * 60 * 60 * 1000)
    ),
  });
}

// Function to create user challenges
async function createUserChallenges(userId) {
  const challengesRef = db.collection('challenges');

  await challengesRef.add({
    userId: userId,
    type: 'VR_SESSIONS',
    title: 'VR Sessions',
    current: 0,
    target: 2,
    date: admin.firestore.Timestamp.now(),
  });

  await challengesRef.add({
    userId: userId,
    type: 'VR_HOURS',
    title: 'Hours in VR',
    current: 0,
    target: 4,
    date: admin.firestore.Timestamp.now(),
  });
}

// Speech Analysis Endpoints

// Upload speech audio file from VR
app.post("/api/speech/upload", verifyToken, upload.single('audio'), async (req, res) => {
  const userId = req.user.uid;
  
  if (!req.file) {
    return res.status(400).json({ error: "No audio file provided" });
  }

  try {
    // 1. Upload file to Google Cloud Storage
    const filePath = req.file.path;
    const fileName = `speech-files/${userId}/${Date.now()}-${path.basename(filePath)}`;
    
    // Create bucket if it doesn't exist
    try {
      await storage.createBucket(bucketName);
    } catch (error) {
      // Bucket might already exist, continue
      console.log("Bucket exists or error creating bucket:", error.message);
    }
    
    // Upload file to bucket
    await storage.bucket(bucketName).upload(filePath, {
      destination: fileName,
      metadata: {
        contentType: req.file.mimetype,
      },
    });
    
    const gcsUri = `gs://${bucketName}/${fileName}`;
    const publicUrl = `https://storage.googleapis.com/${bucketName}/${fileName}`;
    
    // 2. Transcribe audio using Whisper API
    const transcriptionData = await transcribeAudio(filePath);
    
    // 3. Analyze speech for metrics
    const analysis = await analyzeSpeech(filePath);
    
    // 4. Save results to Firestore
    const sessionId = uuidv4();
    const sessionRef = db.collection("speech_analysis").doc(sessionId);
    
    await sessionRef.set({
      userId,
      transcript: transcriptionData.text,
      audioUrl: publicUrl,
      wordTimings: transcriptionData.segments,
      analysis,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // 5. Clean up local files
    fs.unlinkSync(filePath);
    
    res.json({
      message: "Speech analysis completed successfully",
      sessionId,
      transcript: transcriptionData.text,
      analysis,
    });
    
  } catch (error) {
    console.error("Error processing speech:", error);
    res.status(500).json({ error: "Error processing speech: " + error.message });
  }
});

// Get all speech analysis sessions for a user
app.get("/api/speech/sessions", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  
  try {
    const sessionsSnapshot = await db.collection("speech_analysis")
      .where("userId", "==", userId)
      .orderBy("timestamp", "desc")
      .get()
      .catch(error => {
        // Check if this is an index error
        if (error.code === 9 && error.message.includes('index')) {
          console.error("Firestore index error:", error.message);
          
          // Extract the URL if it exists in the error message
          // The URL is typically in the format: https://console.firebase.google.com/v1/r/project/...
          const urlMatch = error.message.match(/(https:\/\/console\.firebase\.google\.com[^\s"]+)/);
          const indexUrl = urlMatch ? urlMatch[1] : null;
          
          console.log("Firebase Index Creation URL:", indexUrl);
          
          throw {
            code: 'MISSING_INDEX',
            message: 'The query requires a Firestore index',
            indexUrl: indexUrl
          };
        }
        throw error;
      });
    
    const sessions = [];
    sessionsSnapshot.forEach(doc => {
      const data = doc.data();
      sessions.push({
        id: doc.id,
        transcript: data.transcript,
        analysis: data.analysis,
        timestamp: data.timestamp,
      });
    });
    
    res.json({ sessions });
  } catch (error) {
    console.error("Error fetching speech sessions:", error);
    
    // If it's a missing index error, provide helpful information
    if (error.code === 'MISSING_INDEX') {
      return res.status(409).json({ 
        error: "Missing Firestore index", 
        message: "The database query requires an index to be created. Please follow the link to create it.",
        indexUrl: error.indexUrl,
        // Provide mock data so the app can still function
        sessions: getMockSpeechSessions()
      });
    }
    
    // Return mock data for any other error
    res.json({ 
      sessions: getMockSpeechSessions(),
      mockData: true,
      error: "Using mock data due to database error"
    });
  }
});

// Get detailed analysis for a specific session
app.get("/api/speech/sessions/:id", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  const sessionId = req.params.id;
  
  try {
    const sessionDoc = await db.collection("speech_analysis").doc(sessionId).get();
    
    if (!sessionDoc.exists) {
      return res.status(404).json({ error: "Session not found" });
    }
    
    const sessionData = sessionDoc.data();
    
    // Verify this session belongs to the authenticated user
    if (sessionData.userId !== userId) {
      return res.status(403).json({ error: "Unauthorized access to this session" });
    }
    
    res.json({ session: sessionData });
  } catch (error) {
    console.error("Error fetching session details:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Get speech progress over time
app.get("/api/speech/progress", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  
  try {
    // Check if we can access Firestore
    if (!admin.apps.length || !admin.app().firestore) {
      throw new Error("Firestore not available");
    }
    
    const sessionsSnapshot = await db.collection("speech_analysis")
      .where("userId", "==", userId)
      .orderBy("timestamp", "asc")
      .get()
      .catch(error => {
        // Check if this is an index error
        if (error.code === 9 && error.message.includes('index')) {
          console.error("Firestore index error:", error.message);
          
          // Extract the URL if it exists in the error message
          const urlMatch = error.message.match(/(https:\/\/console\.firebase\.google\.com[^\s"]+)/);
          const indexUrl = urlMatch ? urlMatch[1] : null;
          
          console.log("Firebase Index Creation URL (Progress):", indexUrl);
          
          throw {
            code: 'MISSING_INDEX',
            message: 'The query requires a Firestore index',
            indexUrl: indexUrl
          };
        }
        throw error;
      });
    
    if (sessionsSnapshot.empty) {
      return res.json({ progress: [] });
    }
    
    const progressData = [];
    sessionsSnapshot.forEach(doc => {
      const data = doc.data();
      progressData.push({
        id: doc.id,
        timestamp: data.timestamp,
        overallScore: data.analysis.overallScore,
        confidenceScore: data.analysis.confidenceScore,
        grammarScore: data.analysis.grammarScore,
        clarityScore: data.analysis.clarityScore,
        speechRate: data.analysis.speechRate,
      });
    });
    
    res.json({ progress: progressData });
  } catch (error) {
    console.error("Error fetching speech progress:", error);
    if (error.code === 'MISSING_INDEX') {
      res.status(500).json({ 
        error: "Database query requires indexing", 
        indexUrl: error.indexUrl 
      });
    } else {
      res.status(500).json({ error: "Error fetching speech progress" });
    }
  }
});

// Therapist/Parent API - Get child progress
app.get("/api/therapist/child-progress/:childId", verifyToken, verifyRole(['therapist', 'parent']), async (req, res) => {
  const therapistId = req.user.uid;
  const childId = req.params.childId;
  
  try {
    // First verify that the therapist/parent has a relationship with this child
    const relationshipSnapshot = await db.collection("user_relationships")
      .where("therapistId", "==", therapistId)
      .where("childId", "==", childId)
      .limit(1)
      .get();
    
    // If no relationship found, check parent relationship
    if (relationshipSnapshot.empty && req.userRole === 'parent') {
      const parentRelationshipSnapshot = await db.collection("user_relationships")
        .where("parentId", "==", therapistId)
        .where("childId", "==", childId)
        .limit(1)
        .get();
        
      if (parentRelationshipSnapshot.empty) {
        return res.status(403).json({ error: "Not authorized to view this child's data" });
      }
    } else if (relationshipSnapshot.empty) {
      return res.status(403).json({ error: "Not authorized to view this child's data" });
    }
    
    // Get child progress data
    const sessionsSnapshot = await db.collection("speech_analysis")
      .where("userId", "==", childId)
      .orderBy("timestamp", "asc")
      .get();
    
    if (sessionsSnapshot.empty) {
      return res.json({ progress: [], childInfo: null });
    }
    
    // Get child info
    const childDoc = await db.collection("users").doc(childId).get();
    let childInfo = null;
    
    if (childDoc.exists) {
      const childData = childDoc.data();
      childInfo = {
        uid: childId,
        firstName: childData.firstName,
        lastName: childData.lastName,
        fullName: `${childData.firstName} ${childData.lastName}`,
      };
    }
    
    // Format progress data
    const progressData = [];
    sessionsSnapshot.forEach(doc => {
      const data = doc.data();
      progressData.push({
        id: doc.id,
        timestamp: data.timestamp,
        transcript: data.transcript,
        analysis: data.analysis,
      });
    });
    
    res.json({ 
      progress: progressData,
      childInfo
    });
    
  } catch (error) {
    console.error("Error fetching child progress:", error);
    res.status(500).json({ error: "Error fetching child progress data" });
  }
});

// Therapist/Parent API - Get assigned children
app.get("/api/therapist/children", verifyToken, verifyRole(['therapist', 'parent']), async (req, res) => {
  const userId = req.user.uid;
  const userRole = req.userRole;
  
  try {
    // Query based on role
    let relationshipSnapshot;
    if (userRole === 'therapist') {
      relationshipSnapshot = await db.collection("user_relationships")
        .where("therapistId", "==", userId)
        .get();
    } else {
      // Parent role
      relationshipSnapshot = await db.collection("user_relationships")
        .where("parentId", "==", userId)
        .get();
    }
    
    if (relationshipSnapshot.empty) {
      return res.json({ children: [] });
    }
    
    // Extract childIds
    const childIds = [];
    relationshipSnapshot.forEach(doc => {
      const data = doc.data();
      childIds.push(data.childId);
    });
    
    // Get children information
    const children = [];
    for (const childId of childIds) {
      const childDoc = await db.collection("users").doc(childId).get();
      if (childDoc.exists) {
        const childData = childDoc.data();
        children.push({
          uid: childId,
          firstName: childData.firstName,
          lastName: childData.lastName,
          fullName: `${childData.firstName} ${childData.lastName}`,
          email: childData.email,
        });
      }
    }
    
    res.json({ children });
    
  } catch (error) {
    console.error("Error fetching assigned children:", error);
    res.status(500).json({ error: "Error fetching assigned children" });
  }
});

// Therapist/Parent API - Assign child to therapist/parent
app.post("/api/therapist/assign-child", verifyToken, verifyRole(['therapist', 'parent']), async (req, res) => {
  const userId = req.user.uid;
  const { childEmail } = req.body;
  const userRole = req.userRole;
  
  if (!childEmail) {
    return res.status(400).json({ error: "Child email is required" });
  }
  
  try {
    // Find child by email
    const usersSnapshot = await db.collection("users")
      .where("email", "==", childEmail)
      .where("role", "==", "child")
      .limit(1)
      .get();
    
    if (usersSnapshot.empty) {
      return res.status(404).json({ error: "Child not found or not registered as a child" });
    }
    
    const childDoc = usersSnapshot.docs[0];
    const childId = childDoc.id;
    const childData = childDoc.data();
    
    // Check if relationship already exists
    let relationshipQuery;
    if (userRole === 'therapist') {
      relationshipQuery = db.collection("user_relationships")
        .where("therapistId", "==", userId)
        .where("childId", "==", childId);
    } else {
      // Parent role
      relationshipQuery = db.collection("user_relationships")
        .where("parentId", "==", userId)
        .where("childId", "==", childId);
    }
    
    const existingRelationship = await relationshipQuery.get();
    
    if (!existingRelationship.empty) {
      return res.status(400).json({ error: "Relationship already exists" });
    }
    
    // Create relationship
    const relationshipData = {
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      childId: childId
    };
    
    if (userRole === 'therapist') {
      relationshipData.therapistId = userId;
    } else {
      relationshipData.parentId = userId;
    }
    
    await db.collection("user_relationships").add(relationshipData);
    
    res.status(201).json({
      message: "Child assigned successfully",
      child: {
        uid: childId,
        firstName: childData.firstName,
        lastName: childData.lastName,
        fullName: `${childData.firstName} ${childData.lastName}`,
        email: childData.email,
      }
    });
    
  } catch (error) {
    console.error("Error assigning child:", error);
    res.status(500).json({ error: "Error assigning child" });
  }
});

// Test endpoint for speech analysis (no auth required)
app.post('/api/test/speech/upload', upload.single('audio'), async (req, res) => {
  try {
    console.log('Test endpoint called');
    
    if (!req.file) {
      console.error('No file uploaded');
      return res.status(400).json({ 
        status: 400,
        message: 'No file uploaded',
        data: null
      });
    }
    
    const filePath = req.file.path;
    console.log('File uploaded to:', filePath);
    
    // Analyze the speech
    const result = await analyzeSpeech(filePath);
    
    // Clean up the uploaded file
    try {
      fs.unlinkSync(filePath);
    } catch (error) {
      console.error('Error deleting uploaded file:', error);
    }
    
    // Return the analysis results
    return res.status(result.status).json(result);
  } catch (error) {
    console.error('Error in test speech upload endpoint:', error);
    return res.status(500).json({
      status: 500,
      message: 'Server error processing speech',
      data: null
    });
  }
});

// Helper function to transcribe audio using Whisper
async function transcribeAudio(audioFilePath) {
  const mp3FilePath = `${audioFilePath}.mp3`;
  
  try {
    // Convert audio to MP3 format
    await new Promise((resolve, reject) => {
      ffmpeg(audioFilePath)
        .output(mp3FilePath)
        .audioCodec('libmp3lame')
        .audioBitrate('128k')
        .on('end', resolve)
        .on('error', reject)
        .run();
    });
    
    const formData = new FormData();
    
    if (IS_SELF_HOSTED_WHISPER) {
      // Self-hosted Whisper server format
      formData.append('audio_file', fs.createReadStream(mp3FilePath));
      formData.append('encode', 'true');
      
      try {
        console.log('Sending request to Whisper server at:', WHISPER_API_URL);
        const response = await axios.post(WHISPER_API_URL, formData, {
          headers: formData.getHeaders(),
        });
        
        console.log('Whisper response:', response.data);
        
        // Self-hosted Whisper response format is different
        // It might just return the text directly as a string
        let text = '';
        
        // Check if response.data is a string (direct transcription)
        if (typeof response.data === 'string') {
          text = response.data;
        } 
        // Check if response.data is an object with a text property
        else if (response.data && typeof response.data.text === 'string') {
          text = response.data.text;
        }
        
        console.log('Extracted text:', text);
        
        // Create a simple segments array with the full text
        const segments = [{
          id: 0,
          start: 0,
          end: 1,
          text: text,
          words: text.split(' ').map((word, i) => ({
            word: word,
            start: i * 0.5,
            end: (i + 1) * 0.5
          }))
        }];
        
        return { text, segments };
      } catch (error) {
        console.error('Error calling Whisper API:', error.message);
        throw error;
      }
    } else {
      // OpenAI API format
      formData.append('file', fs.createReadStream(mp3FilePath), {
        filename: path.basename(mp3FilePath),
        contentType: 'audio/mpeg',
      });
      formData.append('model', 'whisper-1');
      formData.append('response_format', 'verbose_json');
      formData.append('language', 'en');
      
      const response = await axios.post(WHISPER_API_URL, formData, {
        headers: {
          ...formData.getHeaders(),
          'Authorization': `Bearer ${WHISPER_API_KEY}`,
        },
      });
      
      return {
        text: response.data.text || '',
        segments: response.data.segments || []
      };
    }
  } catch (error) {
    console.error('Error in transcribeAudio:', error.message);
    // Return a default structure in case of error
    return {
      text: 'Error transcribing audio',
      segments: []
    };
  } finally {
    // Clean up the MP3 file
    if (fs.existsSync(mp3FilePath)) {
      try {
        fs.unlinkSync(mp3FilePath);
      } catch (error) {
        console.error('Error deleting MP3 file:', error.message);
      }
    }
  }
}

// Helper function to analyze speech
async function analyzeSpeech(audioFilePath) {
  try {
    console.log('Starting speech analysis for:', audioFilePath);
    
    // Check if file exists
    if (!fs.existsSync(audioFilePath)) {
      console.error('Audio file does not exist:', audioFilePath);
      return {
        status: 400,
        message: 'Audio file not found',
        data: null
      };
    }
    
    // Step 1: Transcribe audio using Whisper
    console.log('Transcribing audio...');
    const transcriptionResult = await transcribeAudio(audioFilePath);
    
    console.log('Transcription result:', JSON.stringify(transcriptionResult, null, 2));
    
    // Check if we have valid transcription
    if (!transcriptionResult || !transcriptionResult.text || transcriptionResult.text === 'Error transcribing audio') {
      console.error('Failed to transcribe audio or no speech detected');
      return {
        status: 200,
        message: 'No speech detected or unable to analyze speech',
        data: {
          transcript: '',
          overallScore: 0,
          confidenceScore: 0,
          feedback: 'No speech detected or unable to analyze speech',
          detailedAnalysis: []
        }
      };
    }
    
    // Step 2: Analyze the transcription
    const transcript = transcriptionResult.text;
    
    // If transcript is empty or too short, return early
    if (!transcript || transcript.trim().length < 5) {
      console.log('Transcript too short for analysis');
      return {
        status: 200,
        message: 'Speech too short for analysis',
        data: {
          transcript: transcript,
          overallScore: 0,
          confidenceScore: 0,
          feedback: 'Speech too short for meaningful analysis',
          detailedAnalysis: []
        }
      };
    }
    
    // Perform detailed analysis
    const analysisResult = performDetailedAnalysis(transcript);
    
    // Return the analysis results
    return {
      status: 200,
      message: 'Speech analysis completed successfully',
      data: analysisResult
    };
  } catch (error) {
    console.error('Error in analyzeSpeech:', error);
    return {
      status: 500,
      message: 'Error analyzing speech',
      data: null
    };
  }
}

// Detailed speech analysis function
function performDetailedAnalysis(transcript) {
  // Basic statistics
  const words = transcript.split(/\s+/);
  const wordCount = words.length;
  const sentences = transcript.split(/[.!?]+/).filter(Boolean);
  const sentenceCount = sentences.length;
  const avgWordsPerSentence = sentenceCount > 0 ? wordCount / sentenceCount : 0;
  
  // Expanded filler word analysis with more variations
  const fillerWords = [
    'um', 'uh', 'uhm', 'er', 'ah', 'like', 'actually', 'basically', 'literally', 
    'sort of', 'kind of', 'you know', 'i mean', 'so', 'well', 'right', 'anyway',
    'honestly', 'frankly', 'obviously', 'simply', 'just', 'totally', 'essentially'
  ];
  const fillerWordCounts = {};
  let totalFillerWords = 0;
  
  // Convert transcript to lowercase for case-insensitive matching
  const lowerTranscript = transcript.toLowerCase();
  
  // Count filler words with enhanced detection for word boundaries
  fillerWords.forEach(filler => {
    // For multi-word fillers
    if (filler.includes(' ')) {
      const regex = new RegExp(`\\b${filler.replace(/ /g, '\\s+')}\\b`, 'gi');
      const matches = lowerTranscript.match(regex);
      const count = matches ? matches.length : 0;
      
      if (count > 0) {
        fillerWordCounts[filler] = count;
        totalFillerWords += count;
      }
    } else {
      // For single-word fillers, more lenient matching
      const regex = new RegExp(`\\b${filler}\\b`, 'gi');
      const matches = lowerTranscript.match(regex);
      const count = matches ? matches.length : 0;
      
      if (count > 0) {
        fillerWordCounts[filler] = count;
        totalFillerWords += count;
      }
    }
  });

  // Also check for partial repetitions at beginning of sentences
  sentences.forEach(sentence => {
    const trimmedSentence = sentence.trim().toLowerCase();
    if (trimmedSentence.startsWith('so ') || 
        trimmedSentence.startsWith('and ') || 
        trimmedSentence.startsWith('but ') ||
        trimmedSentence.startsWith('like ')) {
      
      const firstWord = trimmedSentence.split(' ')[0];
      fillerWordCounts[firstWord] = (fillerWordCounts[firstWord] || 0) + 1;
      totalFillerWords += 1;
    }
  });
  
  // Calculate filler word percentage
  const fillerWordPercentage = (totalFillerWords / wordCount) * 100;
  
  // Repeated words/phrases analysis (excluding common words)
  const commonWords = ['i', 'you', 'the', 'a', 'an', 'and', 'but', 'or', 'in', 'on', 'at', 'to', 'for', 'with', 'is', 'are', 'was', 'were'];
  const wordFrequency = {};
  
  // Count word frequencies
  words.forEach(word => {
    const cleanWord = word.toLowerCase().replace(/[.,!?;:'"()\-]/g, '');
    if (cleanWord && !commonWords.includes(cleanWord)) {
      wordFrequency[cleanWord] = (wordFrequency[cleanWord] || 0) + 1;
    }
  });
  
  // Find repeated words (occurring more than twice)
  const repeatedWords = Object.entries(wordFrequency)
    .filter(([word, count]) => count > 2)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  
  // Sentiment analysis using natural tokenizer and analyzer
  const tokenizer = new natural.WordTokenizer();
  const analyzer = new natural.SentimentAnalyzer('English', natural.PorterStemmer, 'afinn');
  const tokenizedText = tokenizer.tokenize(transcript);
  const sentimentScore = analyzer.getSentiment(tokenizedText);
  
  // Calculate pauses (approximated by punctuation)
  const pauseIndicators = transcript.match(/[.,!?;:\-]/g);
  const pauseCount = pauseIndicators ? pauseIndicators.length : 0;
  const pausesPerSentence = sentenceCount > 0 ? pauseCount / sentenceCount : 0;
  
  // Calculate confidence score
  // Lower score if: many filler words, excessive repetition, or too many/too few pauses
  let confidenceScore = 75; // Start with a base score
  
  // Adjust based on filler words
  if (fillerWordPercentage > 10) {
    confidenceScore -= 15;
  } else if (fillerWordPercentage > 5) {
    confidenceScore -= 7;
  }
  
  // Adjust based on repeated words
  if (repeatedWords.length > 3) {
    confidenceScore -= 10;
  } else if (repeatedWords.length > 1) {
    confidenceScore -= 5;
  }
  
  // Adjust based on sentence structure
  if (avgWordsPerSentence > 25) {
    confidenceScore -= 10;
  } else if (avgWordsPerSentence < 5 && sentenceCount > 3) {
    confidenceScore -= 5;
  }
  
  // Calculate overall score
  let overallScore = 0;
  
  if (wordCount > 100) {
    overallScore = 85;
  } else if (wordCount > 50) {
    overallScore = 75;
  } else if (wordCount > 20) {
    overallScore = 60;
  } else {
    overallScore = 40;
  }
  
  // Adjust overall score based on filler words and repetition
  overallScore -= (fillerWordPercentage / 2);
  overallScore -= Math.min(repeatedWords.length * 3, 15);
  
  // Ensure scores are in valid range
  confidenceScore = Math.max(0, Math.min(100, Math.round(confidenceScore)));
  overallScore = Math.max(0, Math.min(100, Math.round(overallScore)));
  
  // Generate personalized feedback
  let feedback = '';
  
  if (wordCount < 20) {
    feedback = 'Your speech was quite short. Try to elaborate more on your points.';
  } else {
    feedback = 'You made some good points in your speech.';
  }
  
  if (fillerWordPercentage > 10) {
    feedback += ' You used quite a few filler words, which can make you sound less confident.';
  } else if (fillerWordPercentage > 5) {
    feedback += ' Try to reduce some of the filler words for a more polished delivery.';
  }
  
  if (repeatedWords.length > 2) {
    feedback += ' You repeated some words frequently, which can make your message less engaging.';
  }
  
  if (confidenceScore < 50) {
    feedback += ' Practice can help improve your confidence and delivery.';
  } else if (confidenceScore > 75) {
    feedback += ' You sound quite confident in your delivery.';
  }
  
  // Create detailed analysis categories
  const detailedAnalysis = [
    {
      category: 'Length',
      score: wordCount > 100 ? 90 : (wordCount > 50 ? 75 : (wordCount > 20 ? 60 : 40)),
      feedback: `Speech contains ${wordCount} words.`
    },
    {
      category: 'Structure',
      score: avgWordsPerSentence > 5 && avgWordsPerSentence < 20 ? 85 : 60,
      feedback: `Average of ${avgWordsPerSentence.toFixed(1)} words per sentence.`
    },
    {
      category: 'Filler Words',
      score: 100 - Math.min(fillerWordPercentage * 5, 100),
      feedback: totalFillerWords > 0 ? 
        `Used ${totalFillerWords} filler words (${fillerWordPercentage.toFixed(1)}% of speech).` : 
        'No filler words detected - excellent!'
    },
    {
      category: 'Repetition',
      score: 100 - (repeatedWords.length * 10),
      feedback: repeatedWords.length > 0 ? 
        `Repeated ${repeatedWords.length} words/phrases frequently.` : 
        'Good variety of words without excessive repetition.'
    },
    {
      category: 'Tone',
      score: Math.round((sentimentScore + 1) * 50), // Convert -1 to 1 scale to 0-100
      feedback: sentimentScore > 0.3 ? 'Positive tone throughout.' : 
               (sentimentScore < -0.3 ? 'Negative tone detected.' : 'Neutral tone throughout.')
    }
  ];
  
  return {
    transcript,
    overallScore,
    confidenceScore,
    feedback,
    detailedAnalysis,
    fillerWords: Object.entries(fillerWordCounts).map(([word, count]) => ({ word, count })),
    repeatedWords: repeatedWords.map(([word, count]) => ({ word, count })),
    speechStats: {
      wordCount,
      sentenceCount,
      avgWordsPerSentence,
      fillerWordPercentage
    }
  };
}

// Retrieve VR videos (User fetches from frontend)
app.get("/vr-videos", async (req, res) => {
  try {
    const [files] = await bucket.getFiles({ prefix: "vr_videos/" });
    const videoUrls = files.map((file) => file.publicUrl());
    res.json({ vrVideos: videoUrls });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Retrieve Avatars (User fetches from frontend)
app.get("/avatars", async (req, res) => {
  try {
    const [files] = await bucket.getFiles({ prefix: "avatars/" });
    const avatarUrls = files.map((file) => file.publicUrl());
    res.json({ avatars: avatarUrls });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start the server
app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running on http://0.0.0.0:${PORT}`);
});

console.log("Google Cloud Credentials:", process.env.GOOGLE_APPLICATION_CREDENTIALS);
console.log("MongoDB URI:", process.env.MONGO_URI);

// Helper function to get mock speech sessions
function getMockSpeechSessions() {
  const now = Math.floor(Date.now() / 1000);
  return [
    {
      id: "mock-session-1",
      transcript: "This is a mock transcript for testing. The backend database connection is currently unavailable, so we're showing sample data.",
      analysis: {
        overallScore: 75,
        confidenceScore: 80,
        grammarScore: 70,
        clarityScore: 85,
        speechRate: 120,
        fillerWordCount: 3,
        pauseCount: 2,
        feedback: [
          "Good overall delivery",
          "Try to improve grammar slightly",
          "This is mock data since the database is unavailable"
        ]
      },
      timestamp: {
        _seconds: now - 86400,
        _nanoseconds: 0
      }
    },
    {
      id: "mock-session-2",
      transcript: "This is another mock transcript with different scores. In a real application, this would contain your actual speech content.",
      analysis: {
        overallScore: 82,
        confidenceScore: 85,
        grammarScore: 78,
        clarityScore: 88,
        speechRate: 125,
        fillerWordCount: 1,
        pauseCount: 3,
        feedback: [
          "Excellent confidence and clarity",
          "Good pace of speech",
          "Consider adding more varied sentence structures"
        ]
      },
      timestamp: {
        _seconds: now - 172800, // 2 days ago
        _nanoseconds: 0
      }
    }
  ];
}

// Helper function to get mock progress data
function getMockProgressData() {
  const now = Math.floor(Date.now() / 1000);
  return [
    {
      id: "mock-progress-1",
      timestamp: { _seconds: now - 86400 * 14, _nanoseconds: 0 },
      overallScore: 60,
      confidenceScore: 55,
      grammarScore: 65,
      clarityScore: 60,
      speechRate: 105
    },
    {
      id: "mock-progress-2",
      timestamp: { _seconds: now - 86400 * 10, _nanoseconds: 0 },
      overallScore: 65,
      confidenceScore: 60,
      grammarScore: 70,
      clarityScore: 65,
      speechRate: 110
    },
    {
      id: "mock-progress-3",
      timestamp: { _seconds: now - 86400 * 7, _nanoseconds: 0 },
      overallScore: 70,
      confidenceScore: 65,
      grammarScore: 75,
      clarityScore: 70,
      speechRate: 115
    },
    {
      id: "mock-progress-4",
      timestamp: { _seconds: now - 86400 * 5, _nanoseconds: 0 },
      overallScore: 75,
      confidenceScore: 70,
      grammarScore: 75,
      clarityScore: 80,
      speechRate: 118
    },
    {
      id: "mock-progress-5",
      timestamp: { _seconds: now - 86400 * 2, _nanoseconds: 0 },
      overallScore: 80,
      confidenceScore: 80,
      grammarScore: 75,
      clarityScore: 85,
      speechRate: 120
    }
  ];
}
