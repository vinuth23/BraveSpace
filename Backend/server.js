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

  // Fetch user data from the database (you can use Firebase Firestore or any database)
  // For simplicity, let's just send back the UID
  res.json({
    message: `Hello, user with UID: ${userId}`,
  });
});


// User Sign-Up (Create a new user with email and password)
app.post("/signup", async (req, res) => {
  const { email, password, firstName, lastName } = req.body;

  if (!email || !password || !firstName || !lastName) {
    return res.status(400).send({ error: "All fields are required!" });
  }

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`
    });
    const db = admin.firestore();
    await db.collection("users").doc(userRecord.uid).set({
      firstName,
      lastName,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.status(201).send({
      message: "User created successfully!",
      uid: userRecord.uid,
      fullName: `${firstName} ${lastName}`
    });
  } catch (error) {
    res.status(400).send({ error: error.message });
  }
});

// User Sign-In (Verify the user and return a token)
app.post("/signin", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await admin.auth().getUserByEmail(email);
    // Firebase doesn't support password-based sign-in directly in the Admin SDK,
    // but we can generate a custom token to allow users to authenticate.
    const token = await admin.auth().createCustomToken(user.uid);
    res.send({ token });
  } catch (error) {
    res.status(400).send({ error: error.message });
  }
});

// Update the verifyToken endpoint
app.post("/verifyToken", async (req, res) => {
  console.log('📝 Received verifyToken request');
  const { idToken } = req.body;

  if (!idToken) {
    console.log('❌ No token provided in request');
    return res.status(400).json({ error: "No token provided" });
  }

  try {
    console.log('🔍 Verifying token...');
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    console.log('✅ Token verified for user:', decodedToken.uid);
    
    // Get user data from Firestore
    const db = admin.firestore();
    console.log('📚 Fetching user data from Firestore...');
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    
    const response = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      userData: userDoc.data(),
      message: "Token verified successfully"
    };
    
    console.log('✨ Sending successful response');
    res.json(response);
  } catch (error) {
    console.error("❌ Error verifying token:", error);
    res.status(401).json({ error: error.message });
  }
});

// Example of using the middleware to protect routes
app.get("/protected-route", verifyToken, (req, res) => {
  res.json({ 
    message: "This is a protected route",
    user: req.user 
  });
});

// Test endpoint
app.get("/", (req, res) => {
  res.send("BraveSpace Backend is working!");
});

// Add this new test endpoint
app.get("/test-auth", verifyToken, (req, res) => {
  res.json({
    message: "You are authenticated!",
    user: {
      uid: req.user.uid,
      email: req.user.email,
      name: req.user.name
    }
  });
});

// Add error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on http://0.0.0.0:3000');
});
