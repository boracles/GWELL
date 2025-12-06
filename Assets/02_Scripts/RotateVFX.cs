using UnityEngine;

public class RotateVFX : MonoBehaviour
{
    public float speed = 20f;

    void Update()
    {
        transform.Rotate(0f, speed * Time.deltaTime, 0f, Space.World);
    }
}
