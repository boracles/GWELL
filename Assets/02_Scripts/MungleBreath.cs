using UnityEngine;

public class MungleBreath : MonoBehaviour
{
    public Material mat;
    public float min = 0.0f;   // 0~1
    public float max = 1.0f;   // 0~1
    public float speed = 1.0f; // 숨쉬는 속도

    float t;

    void Update()
    {
        t += Time.deltaTime * speed;
        float s = Mathf.Sin(t) * 0.5f + 0.5f; // 0~1
        float breath = Mathf.Lerp(min, max, s);
        mat.SetFloat("_Breath", breath);
    }
}
