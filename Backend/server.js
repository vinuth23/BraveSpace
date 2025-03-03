// Import required modules
const admin = require("firebase-admin");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const mongoose = require("mongoose");
const multer = require("multer");
const { Storage } = require("@google-cloud/storage");
const path = require("path");
require("dotenv").config(); // Load environment variables

const app = express();
const port = 3000;

// Middleware
app.use(bodyParser.json());
app.use(cors());

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// MongoDB connection
mongoose
  .connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log("✅ MongoDB connected"))
  .catch((err) => console.error("❌ MongoDB connection error:", err));

// Google Cloud Storage setup
const storage = new Storage({ keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS });
const bucket = storage.bucket("your-gcs-bucket-name"); // Replace with your actual bucket name

// Multer storage config for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
});

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
app.listen(port, "0.0.0.0", () => {
  console.log(`✅ Server running on http://0.0.0.0:${port}`);
});

console.log("Google Cloud Credentials:", process.env.GOOGLE_APPLICATION_CREDENTIALS);
console.log("MongoDB URI:", process.env.MONGO_URI);
