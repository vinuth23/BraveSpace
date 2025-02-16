// Import Firebase Admin SDK
const admin = require("firebase-admin");
const express = require("express");
const bodyParser = require("body-parser");

const app = express();
const port = 3000;

// Middleware to parse JSON request bodies
app.use(bodyParser.json());

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// User Sign-Up (Create a new user with email and password)
app.post("/signup", async (req, res) => {
  const { email, password } = req.body;

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
    });
    res.status(201).send({
      message: "User created successfully!",
      uid: userRecord.uid,
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

// Test endpoint
app.get("/", (req, res) => {
  res.send("BraveSpace Backend is working!");
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
