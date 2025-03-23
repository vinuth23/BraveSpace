using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class AnimationStopper : MonoBehaviour
{
    public Animator animator;
    // Speech-to-text button removed as we're not using Google speech
    
    // Start is called before the first frame update
    void Start()
    {
                
    }

    public void StopAnimationEvent(){
        
       // animator.Play("Idle");
        animator.enabled = false;
        // Button click removed to prevent Google speech popup
    }
}
