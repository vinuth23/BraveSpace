const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const path = require('path');

// Check if audio file path is provided
if (process.argv.length < 3) {
  console.error('Please provide an audio file path as an argument');
  process.exit(1);
}

const audioFilePath = process.argv[2];

// Check if the file exists
if (!fs.existsSync(audioFilePath)) {
  console.error(`File not found: ${audioFilePath}`);
  process.exit(1);
}

console.log(`Testing Whisper server with file: ${audioFilePath}`);

// Create form data
const formData = new FormData();
formData.append('audio_file', fs.createReadStream(audioFilePath));
formData.append('encode', 'true');

// Send request to Whisper server
axios.post('http://localhost:9000/asr', formData, {
  headers: formData.getHeaders(),
})
  .then(response => {
    console.log('Response status:', response.status);
    console.log('Response data:', response.data);
  })
  .catch(error => {
    console.error('Error:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }); 