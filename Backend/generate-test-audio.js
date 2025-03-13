const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Function to generate a test audio file using PowerShell's text-to-speech
function generateTestAudio(outputPath, text) {
  const script = `
    Add-Type -AssemblyName System.Speech
    $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.SetOutputToWaveFile("${outputPath.replace(/\\/g, '\\\\')}")
    $synthesizer.Speak("${text.replace(/"/g, '\\"')}")
    $synthesizer.Dispose()
  `;
  
  const tempScriptPath = path.join(__dirname, 'temp-tts-script.ps1');
  fs.writeFileSync(tempScriptPath, script);
  
  console.log(`Generating test audio file at: ${outputPath}`);
  console.log(`Text: "${text}"`);
  
  exec(`powershell -ExecutionPolicy Bypass -File "${tempScriptPath}"`, (error, stdout, stderr) => {
    // Delete the temporary script
    fs.unlinkSync(tempScriptPath);
    
    if (error) {
      console.error(`Error generating audio: ${error.message}`);
      return;
    }
    
    if (stderr) {
      console.error(`Error output: ${stderr}`);
      return;
    }
    
    console.log(`Audio file generated successfully at: ${outputPath}`);
  });
}

// Sample text for testing
const sampleText = "Hello, this is a test of the speech analysis system. I am speaking clearly and confidently to test how well the system can analyze my speech patterns. This should provide a good baseline for testing the speech analysis functionality.";

// Output path for the audio file
const outputPath = path.join(__dirname, 'test-audio.wav');

// Generate the test audio
generateTestAudio(outputPath, sampleText); 