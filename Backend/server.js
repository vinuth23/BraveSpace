// Import Firebase Admin SDK
const admin = require("firebase-admin");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware to parse JSON request bodies
app.use(bodyParser.json());
app.use(cors());

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Middleware to verify the ID token
function verifyToken(req, res, next) {
  const idToken = req.headers.authorization?.split('Bearer ')[1];

  if (!idToken) {
    return res.status(401).json({ error: "No token provided" });
  }

  admin
    .auth()
    .verifyIdToken(idToken)
    .then((decodedToken) => {
      req.user = decodedToken;
      next();
    })
    .catch((error) => {
      console.error("Error verifying token:", error);
      res.status(401).json({ error: "Invalid token" });
    });
}

// Protect the /profile route
app.get("/profile", verifyToken, (req, res) => {
  const userId = req.user.uid; // Get the authenticated user's UID

  res.json({
    message: `Hello, user with UID: ${userId}`,
  });
});

// User Sign-Up (Create a new user with email and password)
app.post("/signup", async (req, res) => {
  const { uid, email, firstName, lastName } = req.body;

  if (!uid || !email || !firstName || !lastName) {
    return res.status(400).send({ error: "All fields are required!" });
  }

  try {
    await db.collection('users').doc(uid).set({
      firstName,
      lastName,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await createInitialUserData(uid);

    res.status(201).send({
      message: "User data created successfully!",
      uid: uid,
      fullName: `${firstName} ${lastName}`,
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

// Server listening
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on http://0.0.0.0:3000');
});
