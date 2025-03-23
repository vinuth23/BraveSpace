const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');

// Get the audio file path from command line arguments
const audioFilePath = process.argv[2] || 'test-audio.wav';

// Check if the file exists
if (!fs.existsSync(audioFilePath)) {
  console.error(`Error: File ${audioFilePath} does not exist`);
  process.exit(1);
}

console.log(`Testing speech analysis with file: ${audioFilePath}`);

// Create a form data object
const formData = new FormData();
formData.append('audio', fs.createReadStream(audioFilePath));

// Send the request to the test endpoint
const serverUrl = process.env.SERVER_URL || 'http://localhost:5000';
const endpoint = '/api/test/speech/upload';

console.log(`Sending request to: ${serverUrl}${endpoint}`);
console.log('This may take a minute or two as the speech recognition model processes the audio...');

axios.post(`${serverUrl}${endpoint}`, formData, {
  headers: {
    ...formData.getHeaders(),
  },
  timeout: 120000, // 2 minutes timeout
})
.then(response => {
  console.log('Response received!');
  console.log('Response status:', response.status);
  console.log('Response data:', JSON.stringify(response.data, null, 2));
})
.catch(error => {
  console.error('Error occurred:', error.message);
  if (error.response) {
    console.error('Response status:', error.response.status);
    console.error('Response data:', error.response.data);
  } else if (error.request) {
    console.error('No response received. Request:', error.request._currentUrl);
  } else {
    console.error('Error setting up request:', error.message);
  }
}); 