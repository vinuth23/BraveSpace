using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    public float speed = 10f;
    public float gravity = 9.8f;
    public float turnSmoothTime = 0.1f;

    private CharacterController controller;
    private Animator animator;
    private Vector3 velocity;
    private float turnSmoothVelocity;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
    }

    void Update()
    {
        float moveX = Input.GetAxis("Horizontal");
        float moveZ = Input.GetAxis("Vertical");

        Debug.Log("MoveX: " + moveX + " MoveZ: " + moveZ); // Debug input

        Vector3 moveDirection = transform.forward * moveZ + transform.right * moveX;

        if (moveDirection.magnitude >= 0.1f)
        {
            float targetAngle = Mathf.Atan2(moveDirection.x, moveDirection.z) * Mathf.Rad2Deg;
            float angle = Mathf.SmoothDampAngle(transform.eulerAngles.y, targetAngle, ref turnSmoothVelocity, turnSmoothTime);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);

            controller.Move(moveDirection * speed * Time.deltaTime);

            if (animator != null) animator.SetBool("Running", true);
        }
        else
        {
            if (animator != null) animator.SetBool("Running", false);
        }

        // Apply gravity
        if (!controller.isGrounded)
        {
            velocity.y -= gravity * Time.deltaTime;
        }
        else
        {
            velocity.y = -2f;
        }

        controller.Move(velocity * Time.deltaTime);
    }
}
