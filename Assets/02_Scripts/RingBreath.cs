using UnityEngine;

public class RingBreath : MonoBehaviour
{
    public Transform ring;      // StandbyRing
    public Material ringMat;    // 파티클 머티리얼

    public float minScale = 0.95f;
    public float maxScale = 1.05f;
    public float minAlpha = 0.4f;
    public float maxAlpha = 1.0f;
    public float speed = 0.3f;  // 숨쉬는 속도 (느리게)

    float t;

    void Update()
    {
        t += Time.deltaTime * speed;
        float k = Mathf.Sin(t) * 0.5f + 0.5f; // 0~1

        // 스케일 숨쉬기
        if (ring != null)
        {
            float s = Mathf.Lerp(minScale, maxScale, k);
            ring.localScale = Vector3.one * s;
        }

        // 알파 숨쉬기
        if (ringMat != null)
        {
            var c = ringMat.color;
            c.a = Mathf.Lerp(minAlpha, maxAlpha, k);
            ringMat.color = c;
        }
    }
}
