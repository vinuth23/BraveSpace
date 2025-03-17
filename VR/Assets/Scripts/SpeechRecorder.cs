using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;
using TMPro;

public class SpeechRecorder : MonoBehaviour
{
    [Header("Recording Settings")]
    [SerializeField] private int recordingFrequency = 16000;
    [SerializeField] private int recordingLength = 60; // in seconds
    [SerializeField] private bool autoStopRecording = true;
    
    [Header("UI Elements")]
    [SerializeField] private Button startRecordingButton;
    [SerializeField] private Button stopRecordingButton;
    [SerializeField] private TextMeshProUGUI statusText;
    [SerializeField] private Image recordingIndicator;
    
    [Header("Backend Settings")]
    [SerializeField] private string backendUrl = "http://172.20.10.7:5000/api/speech/upload";
    [SerializeField] private string authToken = ""; // Set this at runtime after user logs in
    
    private AudioClip recordingClip;
    private bool isRecording = false;
    private float recordingTime = 0f;
    private string microphoneDevice;
    
    // Event for notifying when speech analysis is complete
    public event Action<SpeechAnalysisResult> OnSpeechAnalysisComplete;
    
    // Start is called before the first frame update
    void Start()
    {
        // Check if microphone is available
        if (Microphone.devices.Length <= 0)
        {
            Debug.LogError("No microphone detected!");
            if (statusText != null)
                statusText.text = "Error: No microphone detected!";
            return;
        }
        
        microphoneDevice = Microphone.devices[0]; // Use the first available microphone
        Debug.Log("Using microphone: " + microphoneDevice);
        
        // Setup UI
        if (startRecordingButton != null)
            startRecordingButton.onClick.AddListener(StartRecording);
        
        if (stopRecordingButton != null)
        {
            stopRecordingButton.onClick.AddListener(StopRecording);
            stopRecordingButton.interactable = false;
        }
        
        if (statusText != null)
            statusText.text = "Ready to record";
        
        if (recordingIndicator != null)
            recordingIndicator.enabled = false;
    }
    
    // Method to set UI references from another script
    public void SetUIReferences(Button startButton, Button stopButton, TextMeshProUGUI status, Image indicator)
    {
        startRecordingButton = startButton;
        stopRecordingButton = stopButton;
        statusText = status;
        recordingIndicator = indicator;
        
        // Setup UI
        if (startRecordingButton != null)
            startRecordingButton.onClick.AddListener(StartRecording);
        
        if (stopRecordingButton != null)
        {
            stopRecordingButton.onClick.AddListener(StopRecording);
            stopRecordingButton.interactable = false;
        }
        
        if (statusText != null)
            statusText.text = "Ready to record";
        
        if (recordingIndicator != null)
            recordingIndicator.enabled = false;
    }
    
    // Update is called once per frame
    void Update()
    {
        if (isRecording)
        {
            recordingTime += Time.deltaTime;
            
            if (statusText != null)
                statusText.text = $"Recording... {recordingTime:F1}s";
            
            // Blink recording indicator
            if (recordingIndicator != null)
                recordingIndicator.enabled = Mathf.FloorToInt(recordingTime * 2) % 2 == 0;
            
            // Auto-stop recording if enabled and time is up
            if (autoStopRecording && recordingTime >= recordingLength)
            {
                StopRecording();
            }
        }
    }
    
    public void StartRecording()
    {
        if (isRecording)
            return;
        
        Debug.Log("Starting recording...");
        
        // Start recording
        recordingClip = Microphone.Start(microphoneDevice, false, recordingLength, recordingFrequency);
        isRecording = true;
        recordingTime = 0f;
        
        // Update UI
        if (startRecordingButton != null)
            startRecordingButton.interactable = false;
        
        if (stopRecordingButton != null)
            stopRecordingButton.interactable = true;
        
        if (statusText != null)
            statusText.text = "Recording...";
        
        if (recordingIndicator != null)
            recordingIndicator.enabled = true;
    }
    
    public void StopRecording()
    {
        if (!isRecording)
            return;
        
        Debug.Log("Stopping recording...");
        
        // Stop recording
        Microphone.End(microphoneDevice);
        isRecording = false;
        
        // Update UI
        if (startRecordingButton != null)
            startRecordingButton.interactable = true;
        
        if (stopRecordingButton != null)
            stopRecordingButton.interactable = false;
        
        if (statusText != null)
            statusText.text = "Processing...";
        
        if (recordingIndicator != null)
            recordingIndicator.enabled = false;
        
        // Process the recording
        StartCoroutine(ProcessRecording());
    }
    
    private IEnumerator ProcessRecording()
    {
        Debug.Log("Processing recording...");
        
        // Convert AudioClip to WAV
        byte[] wavData = ConvertAudioClipToWav(recordingClip);
        
        // Save WAV file temporarily (optional, for debugging)
        string tempPath = Path.Combine(Application.temporaryCachePath, "recording.wav");
        File.WriteAllBytes(tempPath, wavData);
        Debug.Log("Saved recording to: " + tempPath);
        
        // Send to backend
        yield return StartCoroutine(UploadAudioToBackend(wavData));
    }
    
    private IEnumerator UploadAudioToBackend(byte[] audioData)
    {
        Debug.Log("Uploading to backend...");
        
        if (statusText != null)
            statusText.text = "Uploading...";
        
        // Create form data
        WWWForm form = new WWWForm();
        form.AddBinaryData("audio", audioData, "recording.wav", "audio/wav");
        
        // Create request
        UnityWebRequest www = UnityWebRequest.Post(backendUrl, form);
        
        // Add authorization header if token is available
        if (!string.IsNullOrEmpty(authToken))
            www.SetRequestHeader("Authorization", "Bearer " + authToken);
        
        // Send request
        yield return www.SendWebRequest();
        
        // Check for errors
        if (www.result != UnityWebRequest.Result.Success)
        {
            Debug.LogError("Error uploading audio: " + www.error);
            if (statusText != null)
                statusText.text = "Error: " + www.error;
        }
        else
        {
            Debug.Log("Upload successful!");
            
            // Parse response
            string responseText = www.downloadHandler.text;
            Debug.Log("Response: " + responseText);
            
            if (statusText != null)
                statusText.text = "Analysis complete!";
            
            try
            {
                // Parse the JSON response
                SpeechAnalysisResult result = JsonUtility.FromJson<SpeechAnalysisResult>(responseText);
                
                // Notify listeners
                OnSpeechAnalysisComplete?.Invoke(result);
            }
            catch (System.Exception e)
            {
                Debug.LogError("Error parsing response: " + e.Message);
                if (statusText != null)
                    statusText.text = "Error parsing response";
            }
        }
    }
    
    // Helper method to convert AudioClip to WAV format
    private byte[] ConvertAudioClipToWav(AudioClip clip)
    {
        // Get audio data
        float[] samples = new float[clip.samples];
        clip.GetData(samples, 0);
        
        // Convert to 16-bit PCM
        Int16[] intData = new Int16[samples.Length];
        for (int i = 0; i < samples.Length; i++)
        {
            intData[i] = (Int16)(samples[i] * 32767);
        }
        
        // Create WAV file with header
        using (MemoryStream memoryStream = new MemoryStream())
        {
            using (BinaryWriter writer = new BinaryWriter(memoryStream))
            {
                // WAV header
                writer.Write(new char[4] { 'R', 'I', 'F', 'F' });
                writer.Write(36 + intData.Length * 2);
                writer.Write(new char[4] { 'W', 'A', 'V', 'E' });
                writer.Write(new char[4] { 'f', 'm', 't', ' ' });
                writer.Write(16);
                writer.Write((ushort)1); // PCM format
                writer.Write((ushort)1); // Mono
                writer.Write(recordingFrequency);
                writer.Write(recordingFrequency * 2);
                writer.Write((ushort)2);
                writer.Write((ushort)16);
                writer.Write(new char[4] { 'd', 'a', 't', 'a' });
                writer.Write(intData.Length * 2);
                
                // Audio data
                foreach (Int16 sample in intData)
                {
                    writer.Write(sample);
                }
            }
            
            return memoryStream.ToArray();
        }
    }
    
    // Method to set the auth token (call this after user logs in)
    public void SetAuthToken(string token)
    {
        authToken = token;
        Debug.Log("Auth token set");
    }
    
    // Method to set the backend URL (useful for different environments)
    public void SetBackendUrl(string url)
    {
        backendUrl = url;
        Debug.Log("Backend URL set to: " + url);
    }
} 