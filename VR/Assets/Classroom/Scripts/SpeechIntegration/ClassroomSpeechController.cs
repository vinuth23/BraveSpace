using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine.Networking;

namespace BrainCheck
{
    public class ClassroomSpeechController : MonoBehaviour
    {
        [Header("Recording Settings")]
        public bool autoStartRecording = true;
        public float maxRecordingTime = 180f; // 3 minutes max recording
        public int sampleRate = 44100;
        public float silenceThreshold = 0.005f; // Threshold for detecting silence
        public float silenceTimeout = 5f; // Stop after 5 seconds of silence
        
        [Header("Backend Settings")]
        public string backendUrl = "http://localhost:5000"; // Change this to your backend URL
        public string speechAnalysisEndpoint = "/api/test/speech/upload";
        
        [Header("Animation")]
        public List<Animator> studentAnimators = new List<Animator>(); // Student animators to trigger reactions
        
        private AudioClip _recordingClip;
        private bool _isRecording = false;
        private float _recordingTime = 0f;
        private float _silenceTimer = 0f;
        private string _outputFilePath;
        
        void Start()
        {
            // Check if microphone is available
            if (Microphone.devices.Length <= 0)
            {
                Debug.LogError("No microphone detected!");
                return;
            }
            
            if (autoStartRecording)
            {
                StartRecording();
            }
        }
        
        void Update()
        {
            if (_isRecording)
            {
                _recordingTime += Time.deltaTime;
                
                // Check if max recording time is reached
                if (_recordingTime >= maxRecordingTime)
                {
                    StopRecording();
                    return;
                }
                
                // Check for silence
                float level = GetCurrentAudioLevel();
                
                if (level < silenceThreshold)
                {
                    _silenceTimer += Time.deltaTime;
                    if (_silenceTimer >= silenceTimeout)
                    {
                        // Stop if there's been silence for a while
                        Debug.Log("Stopping due to silence timeout");
                        StopRecording();
                    }
                }
                else
                {
                    // Reset silence timer if sound detected
                    _silenceTimer = 0f;
                }
            }
        }
        
        public void StartRecording()
        {
            if (_isRecording)
                return;
            
            Debug.Log("Starting speech recording...");
            
            if (Microphone.devices.Length <= 0)
            {
                Debug.LogError("No microphone detected!");
                return;
            }
            
            // Start recording using Unity's Microphone class
            _recordingClip = Microphone.Start(null, false, Mathf.CeilToInt(maxRecordingTime), sampleRate);
            _isRecording = true;
            _recordingTime = 0f;
            _silenceTimer = 0f;
        }
        
        public void StopRecording()
        {
            if (!_isRecording)
                return;
            
            Debug.Log("Stopping speech recording...");
            
            // Stop the microphone recording
            Microphone.End(null);
            
            // Only process if we've recorded something meaningful
            if (_recordingTime > 1.0f)
            {
                // Save the recording
                SaveRecording();
                
                // Send the recording to backend
                StartCoroutine(SendAudioToBackend());
            }
            else
            {
                // If recording was too short, just return to Flutter
                StartCoroutine(ReturnToFlutter());
            }
            
            _isRecording = false;
        }
        
        private float GetCurrentAudioLevel()
        {
            if (!_isRecording)
                return 0;
            
            // Get the position of the recording
            int samplePosition = Microphone.GetPosition(null);
            if (samplePosition <= 0)
                return 0;
            
            // Create a temporary buffer
            float[] samples = new float[samplePosition];
            _recordingClip.GetData(samples, 0);
            
            // Calculate RMS amplitude
            float sum = 0;
            for (int i = 0; i < samples.Length; i++)
            {
                sum += samples[i] * samples[i];
            }
            float rms = Mathf.Sqrt(sum / samples.Length);
            
            return rms;
        }
        
        private void SaveRecording()
        {
            string directory = Path.Combine(Application.persistentDataPath, "SpeechRecordings");
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }
            
            string filename = "speech_" + System.DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".wav";
            _outputFilePath = Path.Combine(directory, filename);
            
            // Convert AudioClip to WAV
            SavWav.Save(_outputFilePath, _recordingClip);
            
            Debug.Log("Recording saved to: " + _outputFilePath);
        }
        
        private IEnumerator SendAudioToBackend()
        {
            Debug.Log("Sending audio to backend for analysis...");
            
            // Check if file exists
            if (string.IsNullOrEmpty(_outputFilePath) || !File.Exists(_outputFilePath))
            {
                Debug.LogError("No recording file found!");
                StartCoroutine(ReturnToFlutter()); // Return to Flutter even if error
                yield break;
            }
            
            // Create form with file
            WWWForm form = new WWWForm();
            byte[] audioBytes = File.ReadAllBytes(_outputFilePath);
            form.AddBinaryData("audio", audioBytes, Path.GetFileName(_outputFilePath), "audio/wav");
            
            // Construct the endpoint URL
            string url = backendUrl + speechAnalysisEndpoint;
            
            Debug.Log("Sending request to: " + url);
            
            // Send request
            UnityWebRequest request = UnityWebRequest.Post(url, form);
            
            // Accept all certificates (for development)
            request.certificateHandler = new AcceptAllCertificates();
            request.disposeCertificateHandlerOnDispose = true;
            
            // Send the request
            yield return request.SendWebRequest();
            
            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("Error sending audio: " + request.error);
                // Return to Flutter despite the error
                StartCoroutine(ReturnToFlutter());
            }
            else
            {
                Debug.Log("Audio sent successfully!");
                string response = request.downloadHandler.text;
                Debug.Log("Response: " + response);
                
                ProcessAnalysisResponse(response);
            }
            
            // Clean up
            request.Dispose();
            
            // Optional: Remove the local file after sending
            try {
                File.Delete(_outputFilePath);
                Debug.Log("Deleted temporary audio file");
            } catch (Exception e) {
                Debug.LogWarning("Could not delete temporary file: " + e.Message);
            }
        }
        
        private void ProcessAnalysisResponse(string jsonResponse)
        {
            try
            {
                // Parse the response
                JsonResponse response = JsonUtility.FromJson<JsonResponse>(jsonResponse);
                
                if (response != null && response.data != null)
                {
                    Debug.Log("Speech analysis received: " + response.data.transcript);
                    
                    // Trigger animations based on the transcript content
                    TriggerAnimationsBasedOnAnalysis(response.data);
                }
                else
                {
                    Debug.LogWarning("Invalid response format from backend");
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError("Error processing analysis response: " + e.Message);
            }
            
            // Always return to Flutter after processing (whether successful or not)
            StartCoroutine(ReturnToFlutter());
        }
        
        private IEnumerator ReturnToFlutter()
        {
            // Wait a short amount of time to allow animations to play
            yield return new WaitForSeconds(2.0f);
            
            Debug.Log("Returning to Flutter app...");
            
            try
            {
                // Clean up resources
                if (_recordingClip != null)
                {
                    Destroy(_recordingClip);
                    _recordingClip = null;
                }
                
                #if UNITY_ANDROID
                // For Android
                AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                AndroidJavaObject currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
                currentActivity.Call("finish");
                #elif UNITY_IOS
                // For iOS - using URL scheme
                UnityEngine.iOS.Application.OpenURL("bravespace://returnFromUnity");
                #endif
                
                // For editor testing
                #if UNITY_EDITOR
                UnityEditor.EditorApplication.isPlaying = false;
                #endif
            }
            catch (System.Exception e)
            {
                Debug.LogError("Error returning to Flutter: " + e.Message);
                // Force quit as last resort
                Application.Quit();
            }
        }
        
        private void TriggerAnimationsBasedOnAnalysis(AnalysisData data)
        {
            if (string.IsNullOrEmpty(data.transcript) || studentAnimators.Count == 0)
                return;
            
            // Get the overall score to determine reaction
            float overallScore = data.overallScore;
            
            // Trigger different animations based on score ranges
            foreach (Animator anim in studentAnimators)
            {
                if (anim != null)
                {
                    if (overallScore >= 80)
                    {
                        // Great reaction for high scores
                        anim.SetTrigger("Clap");
                    }
                    else if (overallScore >= 60)
                    {
                        // Medium reaction
                        anim.SetTrigger("Nod");
                    }
                    else
                    {
                        // Basic reaction
                        anim.SetBool("isSitting", true);
                    }
                    
                    // You could also check for specific keywords in the transcript
                    string transcript = data.transcript.ToLower();
                    if (transcript.Contains("hello") || transcript.Contains("hi"))
                    {
                        anim.SetTrigger("Wave");
                    }
                }
            }
        }
    }
    
    // Helper classes for JSON parsing
    [System.Serializable]
    public class JsonResponse
    {
        public int status;
        public string message;
        public AnalysisData data;
    }
    
    [System.Serializable]
    public class AnalysisData
    {
        public string transcript;
        public float overallScore;
        public float confidenceScore;
        public string feedback;
        public AnalysisItem[] detailedAnalysis;
    }
    
    [System.Serializable]
    public class AnalysisItem
    {
        public string category;
        public string comment;
        public float score;
    }
    
    // WAV file saving utility
    public static class SavWav
    {
        private const int HEADER_SIZE = 44;
        
        public static bool Save(string filepath, AudioClip clip)
        {
            if (clip == null)
                return false;
            
            // Make sure directory exists
            Directory.CreateDirectory(Path.GetDirectoryName(filepath));
            
            using (FileStream fileStream = CreateEmpty(filepath))
            {
                ConvertAndWrite(fileStream, clip);
                WriteHeader(fileStream, clip);
            }
            
            return true;
        }
        
        private static FileStream CreateEmpty(string filepath)
        {
            FileStream fileStream = new FileStream(filepath, FileMode.Create);
            byte emptyByte = new byte();
            
            for (int i = 0; i < HEADER_SIZE; i++)
            {
                fileStream.WriteByte(emptyByte);
            }
            
            return fileStream;
        }
        
        private static void ConvertAndWrite(FileStream fileStream, AudioClip clip)
        {
            float[] samples = new float[clip.samples];
            clip.GetData(samples, 0);
            
            Int16[] intData = new Int16[samples.Length];
            
            for (int i = 0; i < samples.Length; i++)
            {
                intData[i] = (short)(samples[i] * 32767);
            }
            
            byte[] byteArray = new byte[intData.Length * 2];
            for (int i = 0; i < intData.Length; i++)
            {
                byte[] byteData = System.BitConverter.GetBytes(intData[i]);
                byteArray[i * 2] = byteData[0];
                byteArray[i * 2 + 1] = byteData[1];
            }
            
            fileStream.Write(byteArray, 0, byteArray.Length);
        }
        
        private static void WriteHeader(FileStream fileStream, AudioClip clip)
        {
            int hz = clip.frequency;
            int channels = clip.channels;
            int samples = clip.samples;
            
            fileStream.Seek(0, SeekOrigin.Begin);
            
            byte[] riff = System.Text.Encoding.UTF8.GetBytes("RIFF");
            fileStream.Write(riff, 0, 4);
            
            byte[] chunkSize = System.BitConverter.GetBytes(fileStream.Length - 8);
            fileStream.Write(chunkSize, 0, 4);
            
            byte[] wave = System.Text.Encoding.UTF8.GetBytes("WAVE");
            fileStream.Write(wave, 0, 4);
            
            byte[] fmt = System.Text.Encoding.UTF8.GetBytes("fmt ");
            fileStream.Write(fmt, 0, 4);
            
            byte[] subChunk1 = System.BitConverter.GetBytes(16);
            fileStream.Write(subChunk1, 0, 4);
            
            UInt16 two = 1; // PCM
            byte[] audioFormat = System.BitConverter.GetBytes(two);
            fileStream.Write(audioFormat, 0, 2);
            
            byte[] numChannels = System.BitConverter.GetBytes(channels);
            fileStream.Write(numChannels, 0, 2);
            
            byte[] sampleRate = System.BitConverter.GetBytes(hz);
            fileStream.Write(sampleRate, 0, 4);
            
            byte[] byteRate = System.BitConverter.GetBytes(hz * channels * 2);
            fileStream.Write(byteRate, 0, 4);
            
            UInt16 blockAlign = (ushort)(channels * 2);
            fileStream.Write(System.BitConverter.GetBytes(blockAlign), 0, 2);
            
            UInt16 bps = 16;
            byte[] bitsPerSample = System.BitConverter.GetBytes(bps);
            fileStream.Write(bitsPerSample, 0, 2);
            
            byte[] dataString = System.Text.Encoding.UTF8.GetBytes("data");
            fileStream.Write(dataString, 0, 4);
            
            byte[] subChunk2 = System.BitConverter.GetBytes(samples * channels * 2);
            fileStream.Write(subChunk2, 0, 4);
            
            fileStream.Flush();
        }
    }

    // Class to accept all certificates
    public class AcceptAllCertificates : UnityEngine.Networking.CertificateHandler
    {
        protected override bool ValidateCertificate(byte[] certificateData)
        {
            // Accept all certificates
            return true;
        }
    }
} 