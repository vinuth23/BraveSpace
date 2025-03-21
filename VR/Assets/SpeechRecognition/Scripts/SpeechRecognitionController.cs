using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

namespace BrainCheck
{
    public class SpeechRecognitionController : MonoBehaviour
    {
        private string gameObjectName = "SpeechRecognitionController";
        private string callbackMethod = "OnSpeechRecognitionCallback";
        public Text outputText;
        public List<Animator> animator = new List<Animator>();
        private Image fadeImage;
        void Start()
        {
            // Set callback method
            SpeechRecognitionBridgeAndroid.setUnityGameObjectNameAndMethodName(gameObjectName, callbackMethod);
        }

        public void OnButtonClick()
        {
            // Set up the plugin
            SpeechRecognitionBridgeAndroid.SetupPlugin();

            // Request microphone permission
            SpeechRecognitionBridgeAndroid.requestMicPermission();

            // Check microphone permission
            SpeechRecognitionBridgeAndroid.checkMicPermission();

            // Set volume levels
            SpeechRecognitionBridgeAndroid.setVolumeForTextToSpeech(2);

            // Convert text to speech
            SpeechRecognitionBridgeAndroid.textToSpeech("", 1, 1.0f);

            // Convert speech to text with pop-ups
            SpeechRecognitionBridgeAndroid.speechToText("en-US");
        }

        // Callback method for speech recognition
        public void OnSpeechRecognitionCallback(string message)
        {
            // Debug.Log("Speech Recognition Callback: " + message);
            outputText.text = message;
            //outputText.text = "Blah BLah";
            if (outputText != null)
            {
                TriggerClappingAnimation();
                
                // Send to Flutter bridge if available
                UnityFlutterBridge bridge = FindObjectOfType<UnityFlutterBridge>();
                if (bridge != null)
                {
                    bridge.OnSpeechRecognized(message);
                }
            }
        }

        public void TriggerClappingAnimation()
        {
            foreach (Animator anim in animator)
            {
                anim.SetBool("isSitting", true);
            }
            
          //  StartCoroutine(FadeOut());
        }

        //private IEnumerator FadeOut()
        //{
        //    float duration = 2f;  // 2 seconds fade-out
        //    float elapsedTime = 0;
        //    Color color = fadeImage.color;

        //    while (elapsedTime < duration)
        //    {
        //        elapsedTime += Time.deltaTime;
        //        color.a = Mathf.Lerp(0, 1, elapsedTime / duration);
        //        fadeImage.color = color;
        //        yield return null;
        //    }
        //    yield return new WaitForSeconds(5f);
        //}
    }
}
