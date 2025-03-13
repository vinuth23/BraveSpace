const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');

// Function to test the Whisper server directly
async function testWhisperServer(audioFilePath) {
  try {
    // Check if the file exists
    if (!fs.existsSync(audioFilePath)) {
      console.error(`File not found: ${audioFilePath}`);
      return;
    }

    console.log(`Testing Whisper server with file: ${audioFilePath}`);
    
    // Create form data
    const formData = new FormData();
    formData.append('audio_file', fs.createReadStream(audioFilePath));
    formData.append('encode', 'true');
    
    // Send request directly to the Whisper server
    const response = await axios.post('http://localhost:9000/asr', formData, {
      headers: formData.getHeaders(),
    });
    
    // Log the response
    console.log('Response status:', response.status);
    console.log('Response data:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('Error testing Whisper server:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

// Check if a file path was provided
if (process.argv.length < 3) {
  console.error('Please provide a path to an audio file');
  console.error('Usage: node test-whisper-directly.js <path-to-audio-file>');
  process.exit(1);
}

// Get the file path from command line arguments
const audioFilePath = process.argv[2];

// Run the test
testWhisperServer(audioFilePath); 