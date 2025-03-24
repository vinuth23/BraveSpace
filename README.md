## Scene Setup Instructions

To fix the scene and prevent Google Speech API popups:

1. Open the Unity project in the VR folder
2. Open the Classroom scene in Classroom/Scenes/Classroom.unity
3. In the Hierarchy, find and select the GameObject named "SpeechRecognitionController"
4. Either disable this GameObject or delete it completely
5. Create a new empty GameObject in the scene
6. Add the "SceneFixHelper" component to this GameObject
7. In the SceneFixHelper Inspector, drag the SpeechRecognitionController GameObject to the "Speech Recognition Controller Object" field
8. Additionally, find any buttons that may be triggering speech recognition (usually labeled with "SpeechToText" or "STT") and disable them
9. Make sure the ClassroomSpeechController component is present in the scene
10. Save the scene

These steps will ensure that:
- The old speech recognition controller is disabled
- Any UI buttons that might trigger the Google speech popup are disabled
- The new silent speech recording system is active

## Troubleshooting

If you still encounter the "InvalidOperationException: Insecure connection not allowed" error:
- Make sure you're using the latest version of the ClassroomSpeechController.cs script
- Check that your backend URL is correctly configured
- The script now includes a certificate handler that accepts all certificates for development purposes 