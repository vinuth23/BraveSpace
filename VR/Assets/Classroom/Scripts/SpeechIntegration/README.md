# Silent Speech Recording for Classroom VR

This document explains how to integrate silent speech recording functionality into the Classroom VR scene, with backend analysis.

## Overview

This integration allows your VR classroom to:
1. Silently record the child's speech during the VR experience
2. Automatically stop recording after silence is detected
3. Send the recording to your backend for analysis
4. Trigger student animations based on the speech analysis results

This approach maintains full immersion by having no UI elements.

## Setup Steps

### 1. Add Speech Recording Controller

1. Open the Classroom scene: `VR/Assets/Classroom/Scenes/Classroom.unity`
2. Create a new empty GameObject in the scene hierarchy
   - Right-click in Hierarchy > Create Empty
   - Rename it to "SpeechRecordingController"
3. Add the `ClassroomSpeechController` component to this GameObject
   - Select the SpeechRecordingController GameObject
   - In the Inspector, click "Add Component"
   - Search for "ClassroomSpeechController" and add it

### 2. Configure the Speech Controller

1. Configure the Recording Settings:
   - `Auto Start Recording`: Set to true to start recording as soon as the scene starts
   - `Max Recording Time`: Maximum duration for recording (default: 3 minutes)
   - `Silence Threshold`: Minimum volume level to detect speech
   - `Silence Timeout`: How long to wait after silence before stopping (default: 2 seconds)

2. Configure the Backend Settings:
   - `Backend URL`: Set to your backend server URL (default: "http://172.20.10.7:5000")
   - `Speech Analysis Endpoint`: API endpoint to process speech (default: "/api/test/speech/upload")

### 3. Link Student Animators to Controller

1. Find animated student characters in the scene
2. Add their Animator components to the SpeechRecordingController
   - Select the SpeechRecordingController GameObject
   - In the Inspector, expand the "Student Animators" list
   - Set the size to match the number of student characters
   - Drag each student's Animator component to the list

### 4. Set Up Required Animation Triggers

Ensure your student character Animator Controllers have the following parameters:
- `isSitting` (bool): Basic state for seated students
- `Clap` (trigger): Used for positive reactions to good speeches
- `Nod` (trigger): Used for medium-positive reactions
- `Wave` (trigger): Triggered when specific keywords are detected

### 5. Test the Integration

1. Enter Play mode in the Editor
2. The recording should start automatically (if Auto Start Recording is enabled)
3. Speak into your microphone
4. The recording will stop automatically after silence is detected
5. The audio will be sent to your backend for analysis
6. Student characters will react based on the analysis results

## Troubleshooting

- If recording isn't working:
  - Check that microphone permissions are granted
  - Verify Microphone.devices array contains available devices
  - Check the Console for any error messages

- If backend connection isn't working:
  - Verify your backend URL is correct
  - Ensure the backend server is running and accessible
  - Check the Console for network error messages

- If students aren't reacting:
  - Ensure Animator parameters match those used in the script
  - Verify the backend is returning valid analysis data
  - Check that the animation triggers match the ones used in the code

## Understanding the Backend Integration

This controller works with your existing backend that:
1. Receives audio files via POST to "/api/test/speech/upload"
2. Uses Whisper for transcription
3. Analyzes the speech content 
4. Returns a JSON response with metrics and feedback

The ClassroomSpeechController parses this response and uses it to trigger appropriate animations on the student characters.

## Technical Details

- Audio is recorded using Unity's Microphone class
- Audio is saved as a WAV file to persistent storage
- Files are sent to the backend using UnityWebRequest
- Response is parsed and used to control character animations
- Silence detection is used to automatically stop recording