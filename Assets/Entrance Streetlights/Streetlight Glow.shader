Shader "Scene/Streetlight Glow"
{
    Properties { _GlowStrength ("Glow Strength", Float) = 1 }
    SubShader
    {
        Tags { "Queue"="Transparent+5" "RenderType"="Transparent" }
        Cull Off
        ZWrite Off
        Blend One One
        Pass
        {
            CGPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            float _GlowStrength;

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 offset : TEXCOORD0;
                float face : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(Varyings,o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 center = UnityObjectToViewPos(float3(0,0,0));
                center.xy += v.vertex.xy * float2(1.32,.57);
                o.position = mul(UNITY_MATRIX_P,float4(center,1));
                o.offset = v.vertex.xy*2;
                o.face = v.normal.z;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                clip(i.face-.9);
                float radius = length(i.offset);
                float falloff = 1-smoothstep(.16,.99,radius);
                float halo = exp(-dot(i.offset,i.offset)*3.6)*falloff;
                float stripe = (1-smoothstep(.39,.78,abs(i.offset.x)))
                    * exp(-abs(i.offset.y)*17);
                return float4(float3(.64,.79,1)*_GlowStrength*(.19*halo+.68*stripe),0);
            }
            ENDCG
        }
    }
}
