# BraveSpace Speech Analysis Backend

This backend service provides speech analysis capabilities for the BraveSpace application using OpenAI's Whisper model for speech-to-text transcription.

## Setup Options

You have two options for setting up the speech recognition service:

### Option 1: Using OpenAI's Whisper API (Requires API Key)

1. Sign up for an OpenAI API key at [https://platform.openai.com/](https://platform.openai.com/)
2. Set your API key as an environment variable:
   ```
   export WHISPER_API_KEY=your-openai-api-key
   ```
3. Install dependencies:
   ```
   npm install
   ```
4. Start the server:
   ```
   npm start
   ```

### Option 2: Self-Hosted Whisper (Free, Requires GPU)

1. Make sure you have Docker and Docker Compose installed
2. For GPU support, ensure you have NVIDIA Container Toolkit installed:
   ```
   # For Ubuntu
   sudo apt-get install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```
3. Start the services:
   ```
   docker-compose up -d
   ```

This will start both the Node.js backend and a self-hosted Whisper server.

## Environment Variables

- `WHISPER_API_URL`: URL for the Whisper API (defaults to OpenAI's endpoint)
- `WHISPER_API_KEY`: API key for OpenAI (not needed for self-hosted option)
- `PORT`: Port to run the server on (defaults to 3000)

## API Endpoints

### POST /api/speech/upload

Uploads an audio file for transcription and analysis.

**Request:**
- Headers:
  - `Authorization: Bearer <token>` - Firebase auth token
- Body:
  - `audio` - Audio file (WAV, MP3, etc.)

**Response:**
```json
{
  "message": "Speech analysis completed successfully",
  "sessionId": "uuid",
  "transcript": "Transcribed text",
  "analysis": {
    "overallScore": 85,
    "confidenceScore": 90,
    "grammarScore": 80,
    "clarityScore": 85,
    "speechRate": 145.5,
    "fillerWordCount": 3,
    "pauseCount": 2,
    "grammarIssues": [],
    "feedback": [
      "Your speaking rate of 145.5 words per minute is excellent!"
    ]
  }
}
```

### GET /api/speech/sessions

Retrieves all speech analysis sessions for the authenticated user.

### GET /api/speech/sessions/:id

Retrieves detailed information about a specific speech analysis session.

### GET /api/speech/progress

Retrieves progress data over time for the authenticated user.

## Troubleshooting

### Self-Hosted Whisper Issues

- If you encounter GPU memory issues, try using a smaller model by changing `ASR_MODEL=base` to `ASR_MODEL=tiny` in the docker-compose.yml file.
- For CPU-only deployment (much slower), remove the `deploy` section from the docker-compose.yml file.

### OpenAI API Issues

- Check your API key and usage limits on the OpenAI dashboard.
- Ensure your audio files are in a supported format (MP3, WAV, etc.).
- The backend automatically converts audio to MP3 format before sending to the API. 