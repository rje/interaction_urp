Shader "Unlit/Oculus Hand Outline URP"
{
    Properties
    {
        [Header(General)]
        _ColorTop("Color Top", Color) = (0.1960784, 0.2039215, 0.2117647, 1)
        _ColorBottom("Color Bottom", Color) = (0.1215686, 0.1254902, 0.1294117, 1)
        _Opacity("Opacity", Range( 0 , 1)) = 0.8

        [Header(Fresnel)]
        _FresnelPower("FresnelPower", Range( 0 , 5)) = 0.16

        [Header(Outline)]
        _OutlineColor("Outline Color", Color) = (0.5377358,0.5377358,0.5377358,1)
        _OutlineWidth("Outline Width", Range( 0 , 0.005)) = 0.00134
        _OutlineOpacity("Outline Opacity", Range( 0 , 1)) = 0.4
        _OutlineIntensity("Outline Intensity", Range( 0 , 1)) = 1
        _OutlinePinchRange("Outline Pinch Range", Float) = 0.15
        _OutlineGlowIntensity("Outline Glow Intensity", Range( 0 , 1)) = 0
        _OutlineGlowColor("Outline Glow Color", Color) = (1,1,1,1)
        _OutlineSphereHardness("Outline Sphere Hardness", Range( 0 , 1)) = 0.3

        [Header(Pinch)]
        _PinchPosition("Pinch Position", Vector) = (0,0,0,0)
        _PinchRange("Pinch Range", Float) = 0.03
        _PinchIntensity("Pinch Intensity", Range( 0 , 1)) = 0
        _PinchColor("Pinch Color", Color) = (0.95,0.95,0.95,1)

        [Header(Wrist)]
        _WristLocalOffset("Wrist Local Offset", Vector) = (0,0,0,0)
        _WristRange("Wrist Range", Float) = 0.06
        _WristScale("Wrist Scale", Float) = 1.0

        [Header(Finger Glow)]
        _FingerGlowMask("Finger Glow Mask", 2D) = "white" {}
        _FingerGlowColor("Finger Glow Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline"
        }
        ZWrite Off
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                half3 normal : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_FingerGlowMask);
            SAMPLER(sampler_FingerGlowMask);
            CBUFFER_START(UnityPerMaterial)
            half4 _ColorTop;
            half4 _ColorBottom;
            float _Opacity;
            float _FresnelPower;
            CBUFFER_END

            // Pinch
            uniform float _PinchRange;
            uniform float3 _PinchPosition;
            uniform float _PinchIntensity;
            uniform float4 _PinchColor;

            // Wrist
            uniform float4 _WristLocalOffset;
            uniform float _WristRange;
            uniform float _WristScale;

            // Finger Glow
            uniform float4 _FingerGlowColor;
            uniform float _ThumbGlowValue;
            uniform float _IndexGlowValue;
            uniform float _MiddleGlowValue;
            uniform float _RingGlowValue;
            uniform float _PinkyGlowValue;


            // Outline
            uniform float _OutlineWidth;
            uniform float _OutlineIntensity;
            uniform float4 _OutlineColor;
            uniform float _OutlinePinchRange;
            uniform float _OutlineSphereHardness;
            uniform float _OutlineGlowIntensity;
            uniform float4 _OutlineGlowColor;
            uniform float _OutlineOpacity;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                UNITY_TRANSFER_INSTANCE_ID(v, OUT);
                OUT.normal = IN.normal;
                float4 vertexPos = IN.positionOS;
                vertexPos.xyz += IN.normal * _OutlineWidth;
                OUT.positionHCS = TransformObjectToHClip(vertexPos);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS).xyz;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float3 mask = ((IN.worldPos - _PinchPosition) / _OutlinePinchRange);
                float dotValue = clamp(dot(mask, mask), 0.0, 1.0);
                float sphereMask = pow(dotValue, _OutlineSphereHardness);

                float outlineGlow = saturate(1.0 - sphereMask) * _OutlineGlowIntensity *
                    _OutlineGlowColor.rgb;

                float3 wristPosition = TransformObjectToWorld(_WristLocalOffset).xyz;
                float wristSphere = length(wristPosition - IN.worldPos);
                float wristRangeScaled = _WristRange * _WristScale;
                float wristSphereStep = smoothstep(wristRangeScaled * 0.333, wristRangeScaled, wristSphere);
                float3 emission = (_OutlineColor.rgb * _OutlineIntensity) + outlineGlow;
                float alpha = _OutlineOpacity * wristSphereStep;

                return half4(emission, alpha);
            }
            ENDHLSL
        }
    }
}