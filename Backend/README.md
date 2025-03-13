# BraveSpace Speech Analysis API

This is the backend service for the BraveSpace platform, which provides speech analysis functionality for improving public speaking skills.

## Features

- Speech transcription using Whisper ASR
- Speech analysis for metrics like word count, sentence structure, etc.
- API endpoints for uploading and analyzing speech recordings
- Docker containerization for easy deployment

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Node.js](https://nodejs.org/) (for local development)
- [npm](https://www.npmjs.com/) (comes with Node.js)

## Setup

1. Clone the repository
2. Navigate to the Backend directory
3. Create a `.env` file with the following variables:
   ```
   PORT=3000
   IS_SELF_HOSTED_WHISPER=true
   WHISPER_API_URL=http://localhost:9000/asr
   WHISPER_API_KEY=not-needed-for-local
   ```
4. Start the Docker containers:
   ```
   docker-compose up -d
   ```

## API Endpoints

### Test Speech Analysis (No Authentication Required)

- **URL**: `/api/test/speech/upload`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Request Body**:
  - `audio`: Audio file (WAV, MP3, etc.)
- **Response**:
  ```json
  {
    "status": 200,
    "message": "Speech analysis completed successfully",
    "data": {
      "transcript": "Transcribed text...",
      "overallScore": 80,
      "confidenceScore": 75,
      "feedback": "Feedback on speech...",
      "detailedAnalysis": [
        {
          "category": "Length",
          "score": 90,
          "feedback": "Speech contains X words."
        },
        {
          "category": "Structure",
          "score": 85,
          "feedback": "Average of Y words per sentence."
        }
      ]
    }
  }
  ```

### Authenticated Speech Analysis

- **URL**: `/api/speech/upload`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Headers**:
  - `Authorization`: `Bearer <firebase-auth-token>`
- **Request Body**:
  - `audio`: Audio file (WAV, MP3, etc.)
  - `title`: Title of the speech (optional)
  - `description`: Description of the speech (optional)
- **Response**: Same as the test endpoint

## Testing

1. Generate a test audio file:
   ```
   node generate-test-audio.js
   ```
2. Test the speech analysis API:
   ```
   node test-speech-api.js test-audio.wav
   ```

## Architecture

- **Backend**: Node.js with Express.js
- **Speech Recognition**: Self-hosted Whisper ASR server
- **Authentication**: Firebase Authentication
- **Database**: Firestore (for storing user data and speech analysis results)

## Docker Services

- **backend**: Node.js backend service
- **whisper-server**: Self-hosted Whisper ASR server

## License

This project is licensed under the MIT License - see the LICENSE file for details. 