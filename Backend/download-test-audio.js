const fs = require('fs');
const path = require('path');
const axios = require('axios');

// Function to download a file
async function downloadFile(url, outputPath) {
  console.log(`Downloading file from: ${url}`);
  console.log(`Saving to: ${outputPath}`);
  
  try {
    const response = await axios({
      method: 'GET',
      url: url,
      responseType: 'stream'
    });
    
    const writer = fs.createWriteStream(outputPath);
    
    response.data.pipe(writer);
    
    return new Promise((resolve, reject) => {
      writer.on('finish', () => {
        console.log('Download completed successfully');
        resolve();
      });
      writer.on('error', (err) => {
        console.error(`Error writing file: ${err.message}`);
        reject(err);
      });
    });
  } catch (error) {
    console.error(`Error downloading file: ${error.message}`);
    throw error;
  }
}

// URL of a sample audio file (this is a public domain audio file)
const audioUrl = 'https://www2.cs.uic.edu/~i101/SoundFiles/gettysburg.wav';

// Output path for the audio file
const outputPath = path.join(__dirname, 'sample-audio.wav');

// Download the file
downloadFile(audioUrl, outputPath)
  .catch(error => {
    console.error('Failed to download the file:', error);
  }); 