using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class AnimationStopper : MonoBehaviour
{
    public Animator animator;
    public Button sttbutton;
    // Start is called before the first frame update
    void Start()
    {
                
    }

    public void StopAnimationEvent(){
        
       // animator.Play("Idle");
        animator.enabled = false;
        sttbutton.onClick.Invoke();
    }
}
