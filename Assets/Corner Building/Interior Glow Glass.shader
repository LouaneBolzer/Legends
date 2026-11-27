Shader "Scene/Interior Glow Glass"
{
    Properties { _EmissionColor ("Interior Light Tint", Color) = (.29,.17,.06,1) }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _EmissionColor;
            CBUFFER_END

            struct Attributes
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            Varyings Vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.position = TransformObjectToHClip(v.position.xyz);
                o.uv = v.uv;
                return o;
            }
            half4 Frag(Varyings i) : SV_Target
            {
                half2 p = (i.uv - .5) * half2(1.35,1);
                half falloff = saturate(1 - dot(p,p));
                half3 darkGlass = half3(.0013,.0017,.0024);
                return half4(darkGlass + _EmissionColor.rgb * lerp(.15,.32,falloff),1);
            }
            ENDHLSL
        }
    }
}