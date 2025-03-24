using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BrainCheck
{
    public class SpeechToTextImplementation : MonoBehaviour
    {

            public Text resultText; // Assign this in Unity UI
            private string gameObjectName = "SpeechToTextManager"; // This script's GameObject name
            private string statusMethodName = "OnSpeechResult"; // Callback function name
            private int milliseconds = 60000; // Timeout for silent mode

            public void StartListening()
            {
                InitializePlugin();
                SpeechRecognitionBridgeAndroid.speechToTextInSilentMode(milliseconds, "en"); // English locale
            }

            private void InitializePlugin()
            {
                Debug.Log("inside initialize plugin func");

                // Set up plugin on start
                SpeechRecognitionBridgeAndroid.SetupPlugin();

                // Request mic permission
                SpeechRecognitionBridgeAndroid.requestMicPermission();

                // Check mic permission asynchronously (result will be received in OnMicPermissionCheck)
                SpeechRecognitionBridgeAndroid.checkMicPermission();
            }

            // This function is called automatically when permission check completes
            public void OnMicPermissionCheck(string status)
            {
                Debug.Log("inside OnMicPermissionCheck  func");

                if (status == "PermissionGranted")
                {
                    // Set the callback to receive speech results
                    SpeechRecognitionBridgeAndroid.setUnityGameObjectNameAndMethodName(gameObjectName, statusMethodName);

                    // Start speech recognition with beep sound
                    //SpeechRecognitionBridgeAndroid.speechToTextInHidenModeWithBeepSound(milliseconds, "en");
                    SpeechRecognitionBridgeAndroid.speechToText("hi");

                }
                else
                {
                    Debug.LogWarning("Microphone permission not granted!");
                }
            }

            // Callback function to receive the recognized speech result
            public void OnSpeechResult(string text)
            {
                Debug.Log("inside OnSpeechResult  func");
                Debug.Log("Recognized Speech: " + text);
                if (!string.IsNullOrEmpty(text))
                {
                    resultText.text = text;
                }
                else
                {
                    resultText.text = "No speech detected. Try again.";
                }

            // Unmute speakers after recognition
           // SpeechRecognitionBridgeAndroid.unmuteSpeakers();
            }
        }
    }
