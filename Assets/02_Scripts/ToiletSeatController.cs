using System.Collections;
using UnityEngine;
using UnityEngine.VFX;

public class ToiletSeatController : MonoBehaviour
{
    [Header("VFX")]
    public VisualEffect vfx;              // SeatT가 있는 VFX Graph
    public string seatTParam = "SeatT";   // 블랙보드에 만든 SeatT 이름

    [Header("Test Input")]
    public KeyCode toggleKey = KeyCode.Space; // 테스트용 키

    [Header("Transition")]
    public float transitionDuration = 1.5f;   // 도넛 -> 로고로 모이는 시간

    bool isSeated;          // 현재 상태(앉음/안 앉음)
    Coroutine transitionCo; // SeatT 보간용 코루틴

    void Start()
    {
        if (vfx == null)
        {
            vfx = GetComponent<VisualEffect>();
        }

        // 시작 상태는 0으로
        vfx.SetFloat(seatTParam, 0f);
        isSeated = false;
    }

    void Update()
    {
        // 테스트: 스페이스바로 앉기/일어나기 토글
        if (Input.GetKeyDown(toggleKey))
        {
            SetSeated(!isSeated);
        }
    }

    /// <summary>
    /// 외부(센서)에서 호출할 함수: true면 앉음, false면 일어남
    /// </summary>
    public void SetSeated(bool seated)
    {
        if (isSeated == seated) return;

        isSeated = seated;

        if (transitionCo != null)
            StopCoroutine(transitionCo);

        transitionCo = StartCoroutine(SeatTransition(seated));
    }

    IEnumerator SeatTransition(bool seated)
    {
        float startT = vfx.GetFloat(seatTParam);
        float targetT = seated ? 1f : 0f;

        float t = 0f;

        while (t < transitionDuration)
        {
            t += Time.deltaTime;
            float u = t / transitionDuration;
            // 조금 더 부드럽게
            u = Mathf.SmoothStep(0f, 1f, u);

            float value = Mathf.Lerp(startT, targetT, u);
            vfx.SetFloat(seatTParam, value);

            yield return null;
        }

        vfx.SetFloat(seatTParam, targetT);
    }

    // 나중에 센서 신호 연결할 때 이런 식으로 쓰면 됨
    public void OnSeatSensorChanged(bool pressed)
    {
        SetSeated(pressed);
    }
}