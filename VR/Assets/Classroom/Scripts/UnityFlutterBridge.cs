using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

public class UnityFlutterBridge : MonoBehaviour
{
    // Reference to your animator controllers
    public List<Animator> studentAnimators = new List<Animator>();
    
    // Reference to speech controller
    private BrainCheck.SpeechRecognitionController speechController;
    
    // Message handler for communication with Flutter
    private static UnityFlutterBridge instance;
    
    void Awake()
    {
        // Singleton pattern
        if (instance == null)
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else if (instance != this)
        {
            Destroy(gameObject);
        }
        
        // Find the speech controller
        speechController = FindObjectOfType<BrainCheck.SpeechRecognitionController>();
        
        // Register to the speech controller event if available
        if (speechController != null)
        {
            Debug.Log("Speech controller found");
        }
        else
        {
            Debug.LogError("Speech controller not found in scene");
        }
    }
    
    // Method to be called from Flutter
    public void HandleFlutterMessage(string message)
    {
        Debug.Log("Message from Flutter: " + message);
        
        switch(message)
        {
            case "StartClassroom":
                StartClassroomScene();
                break;
            case "StopClassroom":
                StopClassroomScene();
                break;
            default:
                Debug.Log("Unknown message: " + message);
                break;
        }
    }
    
    public void StartClassroomScene()
    {
        Debug.Log("Starting classroom scene");
        
        // Start animations and classroom activities
        foreach (Animator anim in studentAnimators)
        {
            if (anim != null)
            {
                anim.SetBool("isSitting", true);
            }
        }
        
        // Connect to your existing speech recognition
        if (speechController != null)
        {
            speechController.OnButtonClick();
        }
    }
    
    public void StopClassroomScene()
    {
        Debug.Log("Stopping classroom scene");
        
        // Reset animations
        foreach (Animator anim in studentAnimators)
        {
            if (anim != null)
            {
                anim.SetBool("isSitting", false);
            }
        }
    }
    
    // Method to send data back to Flutter
    public void SendMessageToFlutter(string message)
    {
        Debug.Log("Sending message to Flutter: " + message);
        
        // This is a placeholder for the actual implementation
        // When you export with flutter_unity_widget, you'll use:
        // UnityMessageManager.Instance.SendMessageToFlutter(message);
        
        // For testing in the Unity Editor, we'll just log it
        #if UNITY_EDITOR
        Debug.Log("Message would be sent to Flutter: " + message);
        #endif
    }
    
    // Call this method when speech recognition is complete
    public void OnSpeechRecognized(string transcript)
    {
        // Create a simple JSON string with the transcript
        string jsonMessage = "{\"transcript\":\"" + transcript + "\",\"duration\":30}";
        SendMessageToFlutter(jsonMessage);
    }
    
    // Add this to your SpeechRecognitionController.cs to call our bridge
    // In OnSpeechRecognitionCallback method:
    // 
    // UnityFlutterBridge bridge = FindObjectOfType<UnityFlutterBridge>();
    // if (bridge != null)
    // {
    //     bridge.OnSpeechRecognized(message);
    // }
} 