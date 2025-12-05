Shader "Custom/MungleFlow"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _FlowTex("Flow (noise)", 2D) = "gray" {}

        _Breath("Breath", Range(0,1)) = 0       // 스크립트에서 넣어줄 값
        _FlowStrength("Flow Strength", Range(0,0.1)) = 0.02
        _FlowTiling("Flow Tiling", Range(0.2,5)) = 1.2
        _FlowSpeed("Flow Speed", Range(0,3)) = 1.0
        _EdgeFade("Edge Fade", Range(0.01,0.3)) = 0.08
        _BlurRadius("Blur Radius", Range(0,0.02)) = 0.004
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        ZWrite Off
        Blend One OneMinusSrcAlpha
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4    _MainTex_ST;
            float4    _MainTex_TexelSize;   // ✅ 이 줄 추가
            
            sampler2D _FlowTex;
            float4    _FlowTex_ST;
            

            float _Breath;
            float _FlowStrength;
            float _FlowTiling;
            float _FlowSpeed;
            float _EdgeFade;
            float _BlurRadius;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos    : SV_POSITION;
                float2 uv     : TEXCOORD0;
                float2 uvFlow : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos    = UnityObjectToClipPos(v.vertex);
                o.uv     = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvFlow = TRANSFORM_TEX(v.uv, _FlowTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
{
    // 0~1 UV → 테두리 2픽셀 안쪽 영역으로 매핑
    float2 baseUVRaw = i.uv;
    float2 margin = _MainTex_TexelSize.xy * 2.0; // 테두리 2픽셀은 안 씀
    float2 baseUV = lerp(margin, 1.0 - margin, baseUVRaw);

    // 숨쉬기 강도
    float breath = _Breath * 0.9 + 0.5;

    // ── 1) 노이즈 기반 제자리 꿀렁
    float2 noiseUV = i.uvFlow * _FlowTiling;
    float3 n = tex2D(_FlowTex, noiseUV).rgb;

    float2 dir   = (n.rg * 2.0 - 1.0);
    float  phase = n.b * 6.28318; // 0~2π

    float t = _Time.y * _FlowSpeed;

    // 아주 느린 파동
    float waveSlow  = sin(t * 0.25 + phase);

    // 디테일용
    float waveFast  = sin(t * 1.1 + phase * 1.37);

    // 섞기
    float wave = waveSlow * 0.75 + waveFast * 0.25;

    // 전체 강도 modulation
    float macro = sin(t * 0.10 + phase * 0.5) * 0.5 + 0.5; // 0~1

    float strength = _FlowStrength * breath * (0.4 + macro * 0.8); // 0.4~1.2배
    float2 offset = dir * wave * strength;

    // ── 2) 가장자리에서 왜곡 줄이기 (부드러운 falloff)
    float2 dist2edge = float2(
        min(baseUVRaw.x, 1.0 - baseUVRaw.x),
        min(baseUVRaw.y, 1.0 - baseUVRaw.y)
    );
    float d = min(dist2edge.x, dist2edge.y);

    float edge = saturate(d / _EdgeFade);
    float edgeMask = edge * edge;   // 부드러운 감쇠
    offset *= edgeMask;

    // ─────────────────────────────
    // 3) 도넛과 비슷한 "링 영역" 계산 (화면 중앙 기준)
    // ─────────────────────────────
    float2 center = float2(0.5, 0.5);
    float2 fromCenter = baseUVRaw - center;
    float radial = length(fromCenter);

    // 링 굵기 영역 (반지름 0.18~0.32 정도만)
    float inner = 0.18;
    float outer = 0.32;
    float ringMask = smoothstep(inner, inner + 0.04, radial) *
                     (1.0 - smoothstep(outer - 0.04, outer, radial));

    // 링 전체를 아주 살짝 팽창/수축시키는 파동 (배경 숨쉬기)
    float ringWave = sin(t * 0.5) * 0.5 + 0.5; // 0~1
    float ringExpand = 0.003 * ringWave * ringMask; // 엄청 미세한 값

    // 중앙에서 바깥방향으로 살짝 밀어줌
    float2 ringOffset = fromCenter * ringExpand;
    // ─────────────────────────────

    // 최종 uv (기존 offset + 링 숨쉬기)
    float2 uv = baseUV + offset + ringOffset;

    // ── 4) 소프트 블러
    float r = _BlurRadius * breath;

    fixed4 c = tex2D(_MainTex, uv);
    c += tex2D(_MainTex, uv + float2( r, 0));
    c += tex2D(_MainTex, uv + float2(-r, 0));
    c += tex2D(_MainTex, uv + float2(0,  r));
    c += tex2D(_MainTex, uv + float2(0, -r));
    c += tex2D(_MainTex, uv + float2( r,  r));
    c += tex2D(_MainTex, uv + float2(-r,  r));
    c += tex2D(_MainTex, uv + float2( r, -r));
    c += tex2D(_MainTex, uv + float2(-r, -r));
    c /= 9.0;

    // ─────────────────────────────
    // 디버그용: 배경색 기반의 "거친 입자"를 강하게 띄우기
    // ─────────────────────────────

    // 랜덤 UV (입자 간격 조절: 40 숫자 키우면 더 촘촘)
    float2 suv = baseUVRaw * 15.0 + float2(t * 0.1, -t * 0.07);
    // 해시 노이즈 0~1
    float h = frac(sin(dot(suv, float2(12.9898, 78.233))) * 43758.5453);

    // 상위 구간만 부드럽게 선택 (입자 밀도)
    float speckMask = smoothstep(0.90, 0.98, h);   // 앞 숫자 ↑ = 점 더 적게

    // 배경색
    float3 baseColor = c.rgb;

    // "조금 더 밝은 버전" — 절대 흰색까지 안 가게
    float3 bright = baseColor * 1.2;        // 15% 정도만 밝게

    // 입자 있는 곳에서만 baseColor → bright 로 살짝 이동
    c.rgb = lerp(baseColor, bright, speckMask * 0.9);


    return c;
}

            ENDCG
        }
    }
}
