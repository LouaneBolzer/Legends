using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
[DisallowMultipleComponent]
public sealed class FirstPersonPlayer : MonoBehaviour
{
    [SerializeField] private Transform view;
    [SerializeField] private float moveSpeed = 3.3f;
    [SerializeField] private float mouseSensitivity = 0.12f;

    private CharacterController controller;
    private Vector3 spawn;
    private Quaternion spawnRotation;
    private float spawnPitch;
    private float pitch;
    private float verticalSpeed;

    private void Awake()
    {
        controller = GetComponent<CharacterController>();
        spawn = transform.position;
        spawnRotation = transform.rotation;
        spawnPitch = Mathf.DeltaAngle(0f, view.localEulerAngles.x);
        pitch = spawnPitch;
    }

    private void Start() => SetCursorLocked(true);

    private void OnDisable() => SetCursorLocked(false);

    private void Update()
    {
        Keyboard keyboard = Keyboard.current;
        Mouse mouse = Mouse.current;
        if (keyboard != null && keyboard.escapeKey.wasPressedThisFrame)
            SetCursorLocked(false);
        else if (mouse != null && mouse.leftButton.wasPressedThisFrame)
            SetCursorLocked(true);

        if (Cursor.lockState == CursorLockMode.Locked && mouse != null)
        {
            Vector2 look = mouse.delta.ReadValue() * mouseSensitivity;
            transform.Rotate(0f, look.x, 0f);
            pitch = Mathf.Clamp(pitch - look.y, -85f, 85f);
            view.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }

        Vector2 movement = Vector2.zero;
        if (Cursor.lockState == CursorLockMode.Locked && keyboard != null)
        {
            movement.x = (keyboard.dKey.isPressed ? 1f : 0f) - (keyboard.aKey.isPressed ? 1f : 0f);
            movement.y = (keyboard.wKey.isPressed ? 1f : 0f) - (keyboard.sKey.isPressed ? 1f : 0f);
            movement = Vector2.ClampMagnitude(movement, 1f);
        }

        verticalSpeed = controller.isGrounded ? -2f : verticalSpeed + Physics.gravity.y * Time.deltaTime;
        Vector3 velocity = (transform.right * movement.x + transform.forward * movement.y) * moveSpeed;
        velocity.y = verticalSpeed;
        controller.Move(velocity * Time.deltaTime);
        if (transform.position.y < -8f)
            ResetToSpawn();
    }

    private void ResetToSpawn()
    {
        controller.enabled = false;
        transform.SetPositionAndRotation(spawn, spawnRotation);
        pitch = spawnPitch;
        view.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        verticalSpeed = 0f;
        controller.enabled = true;
    }

    private static void SetCursorLocked(bool locked)
    {
        Cursor.lockState = locked ? CursorLockMode.Locked : CursorLockMode.None;
        Cursor.visible = !locked;
    }
}
