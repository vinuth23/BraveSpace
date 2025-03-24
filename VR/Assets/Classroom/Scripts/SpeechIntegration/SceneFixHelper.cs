using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

namespace BrainCheck
{
    public class SceneFixHelper : MonoBehaviour
    {
        [SerializeField] private GameObject speechRecognitionControllerObject;
        
        void Start()
        {
            // Disable the old SpeechRecognitionController
            if (speechRecognitionControllerObject != null)
            {
                Debug.Log("Disabling old SpeechRecognitionController");
                speechRecognitionControllerObject.SetActive(false);
            }
            
            // Find and disable any speech recognition buttons
            Button[] allButtons = FindObjectsOfType<Button>();
            foreach (Button button in allButtons)
            {
                if (button.name.Contains("SpeechToText") || button.name.Contains("STT"))
                {
                    Debug.Log("Disabling speech recognition button: " + button.name);
                    button.gameObject.SetActive(false);
                }
            }
            
            // Make sure our ClassroomSpeechController is active
            ClassroomSpeechController speechController = FindObjectOfType<ClassroomSpeechController>();
            if (speechController == null)
            {
                Debug.LogWarning("ClassroomSpeechController not found in scene! Creating one...");
                GameObject speechControllerObj = new GameObject("ClassroomSpeechController");
                speechController = speechControllerObj.AddComponent<ClassroomSpeechController>();
            }
            
            Debug.Log("Scene has been fixed for silent speech recording");
        }
    }
} 