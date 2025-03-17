using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System;

[Serializable]
public class SpeechAnalysisResult
{
    public string transcript;
    public AnalysisMetrics analysis;
}

[Serializable]
public class AnalysisMetrics
{
    public int overallScore;
    public int confidenceScore;
    public int grammarScore;
    public int clarityScore;
    public float speechRate;
    public int fillerWordCount;
    public int pauseCount;
    public List<string> feedback;
}

public class SpeechRecorderUI : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private SpeechRecorder speechRecorder;
    
    [Header("UI Panels")]
    [SerializeField] private GameObject recordingPanel;
    [SerializeField] private GameObject resultsPanel;
    
    [Header("Recording UI")]
    [SerializeField] private Button startButton;
    [SerializeField] private Button stopButton;
    [SerializeField] private TextMeshProUGUI statusText;
    [SerializeField] private Image recordingIndicator;
    
    [Header("Results UI")]
    [SerializeField] private TextMeshProUGUI transcriptText;
    [SerializeField] private TextMeshProUGUI overallScoreText;
    [SerializeField] private TextMeshProUGUI confidenceScoreText;
    [SerializeField] private TextMeshProUGUI grammarScoreText;
    [SerializeField] private TextMeshProUGUI clarityScoreText;
    [SerializeField] private TextMeshProUGUI speechRateText;
    [SerializeField] private TextMeshProUGUI feedbackText;
    [SerializeField] private Button newRecordingButton;
    [SerializeField] private Button viewProgressButton;
    
    [Header("Score Visuals")]
    [SerializeField] private Image overallScoreBar;
    [SerializeField] private Image confidenceScoreBar;
    [SerializeField] private Image grammarScoreBar;
    [SerializeField] private Image clarityScoreBar;
    
    private SpeechAnalysisResult currentResult;
    
    void Start()
    {
        // Initialize UI
        if (recordingPanel != null)
            recordingPanel.SetActive(true);
        
        if (resultsPanel != null)
            resultsPanel.SetActive(false);
        
        // Setup SpeechRecorder references
        if (speechRecorder != null)
        {
            // Pass UI references to the speech recorder
            speechRecorder.SetUIReferences(startButton, stopButton, statusText, recordingIndicator);
            
            // Register for events
            speechRecorder.OnSpeechAnalysisComplete += HandleSpeechAnalysisComplete;
        }
        else
        {
            Debug.LogError("SpeechRecorder reference not set!");
        }
        
        // Setup button listeners
        if (newRecordingButton != null)
            newRecordingButton.onClick.AddListener(StartNewRecording);
        
        if (viewProgressButton != null)
            viewProgressButton.onClick.AddListener(ViewProgress);
    }
    
    private void HandleSpeechAnalysisComplete(SpeechAnalysisResult result)
    {
        currentResult = result;
        DisplayResults();
    }
    
    private void DisplayResults()
    {
        if (currentResult == null)
            return;
        
        // Switch to results panel
        if (recordingPanel != null)
            recordingPanel.SetActive(false);
        
        if (resultsPanel != null)
            resultsPanel.SetActive(true);
        
        // Display transcript
        if (transcriptText != null)
            transcriptText.text = currentResult.transcript;
        
        // Display scores
        if (overallScoreText != null)
            overallScoreText.text = currentResult.analysis.overallScore.ToString();
        
        if (confidenceScoreText != null)
            confidenceScoreText.text = currentResult.analysis.confidenceScore.ToString();
        
        if (grammarScoreText != null)
            grammarScoreText.text = currentResult.analysis.grammarScore.ToString();
        
        if (clarityScoreText != null)
            clarityScoreText.text = currentResult.analysis.clarityScore.ToString();
        
        if (speechRateText != null)
            speechRateText.text = $"{currentResult.analysis.speechRate} WPM";
        
        // Update score bars
        UpdateScoreBar(overallScoreBar, currentResult.analysis.overallScore);
        UpdateScoreBar(confidenceScoreBar, currentResult.analysis.confidenceScore);
        UpdateScoreBar(grammarScoreBar, currentResult.analysis.grammarScore);
        UpdateScoreBar(clarityScoreBar, currentResult.analysis.clarityScore);
        
        // Display feedback
        if (feedbackText != null && currentResult.analysis.feedback != null)
        {
            string feedbackString = string.Join("\n• ", currentResult.analysis.feedback);
            feedbackText.text = "• " + feedbackString;
        }
    }
    
    private void UpdateScoreBar(Image scoreBar, int score)
    {
        if (scoreBar != null)
        {
            scoreBar.fillAmount = score / 100f;
            
            // Update color based on score
            if (score >= 80)
                scoreBar.color = new Color(0.2f, 0.8f, 0.2f); // Green
            else if (score >= 60)
                scoreBar.color = new Color(0.8f, 0.8f, 0.2f); // Yellow
            else
                scoreBar.color = new Color(0.8f, 0.2f, 0.2f); // Red
        }
    }
    
    private void StartNewRecording()
    {
        // Switch back to recording panel
        if (recordingPanel != null)
            recordingPanel.SetActive(true);
        
        if (resultsPanel != null)
            resultsPanel.SetActive(false);
        
        // Reset status
        if (statusText != null)
            statusText.text = "Ready to record";
    }
    
    private void ViewProgress()
    {
        // This would navigate to the progress screen in the mobile app
        // For now, we'll just log a message
        Debug.Log("View progress in mobile app");
    }
} 