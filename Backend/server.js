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
  const idToken = req.headers.authorization; // Get token from the Authorization header

  if (!idToken) {
    return res.status(401).json({ error: "No token provided" });
  }

  admin
    .auth()
    .verifyIdToken(idToken)
    .then((decodedToken) => {
      req.user = decodedToken; // Store decoded user info in the request object
      next(); // Call the next middleware/route handler
    })
    .catch((error) => {
      console.error("Error verifying ID token:", error);
      return res.status(401).json({ error: "Invalid token" });
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

// Add this new endpoint for token verification
app.post("/verifyToken", async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: "No token provided" });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    res.json({
      uid: decodedToken.uid,
      email: decodedToken.email,
      message: "Token verified successfully"
    });
  } catch (error) {
    console.error("Error verifying token:", error);
    res.status(401).json({ error: "Invalid token" });
  }
});

// Test endpoint
app.get("/", (req, res) => {
  res.send("BraveSpace Backend is working!");
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on http://0.0.0.0:3000');
});
