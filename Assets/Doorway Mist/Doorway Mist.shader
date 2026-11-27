Shader "Scene/Doorway Mist"
{
    Properties
    {
        _MistColor ("Moonlit Mist Color", Color) = (0.176,0.150,0.198,1)
        _Density ("Density", Range(0,2)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            float4 _MistColor;
            float _Density;

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float4 position : SV_POSITION;
                float3 world : TEXCOORD0;
                float top : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(Varyings, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.position = UnityObjectToClipPos(v.vertex);
                o.world = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.top = v.normal.y;
                return o;
            }

            float Hash(float2 p)
            {
                float3 q = frac(p.xyx * float3(.1031,.11369,.13787));
                q += dot(q,q.yzx+19.19);
                return frac((q.x+q.y)*q.z);
            }

            float Noise(float2 p)
            {
                float2 b = floor(p), f = frac(p);
                f = f*f*(3-2*f);
                return lerp(lerp(Hash(b),Hash(b+float2(1,0)),f.x),
                            lerp(Hash(b+float2(0,1)),Hash(b+1),f.x),f.y);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                clip(i.top-.9);
                float2 p = i.world.xz;
                float h = i.world.y;
                float2 drift = _Time.y * float2(.13,-.075);
                float2 flow = p - drift + h * float2(.87,-.48);
                float bank = Noise(flow * .092 + 16);
                float billows = Noise(flow * float2(.24,.37) + 31);
                float wisps = Noise(flow * float2(.47,.74) - drift*.31 + 3);
                float cloud = bank*.55 + billows*.31 + wisps*.14;
                float density = smoothstep(.12,.76,cloud);

                // The doorway is at (6.1, -6.1). The lane runs outward along its normal.
                float2 fromDoor = p - float2(6.1,-6.1);
                float along = dot(fromDoor,float2(.707107,-.707107));
                float across = abs(dot(fromDoor,float2(.707107,.707107)));
                float laneWidth = 1.45 + .27*(Noise(float2(along*.62,_Time.y*.095))-.5);
                float lane = (1-smoothstep(laneWidth*.58,laneWidth+1.18,across))
                    * smoothstep(-1.15,.14,along) * (1-smoothstep(23,39,along));
                float laneDensity = lerp(1,.085,lane);

                // Ease the mist out at the shell and at the perimeter.
                float shell = max(max(-p.x-12,p.x-8), max(-p.y-8,p.y-9));
                shell = max(shell,(p.x-p.y-12.2)*.707107);
                float outside = lerp(.13,1,smoothstep(-.75,.55,shell));
                float extent = 1-smoothstep(35,46,length(p-float2(1,-3))+2.4*(bank-.5));
                float height = exp(-max(0,h)*.67) * (1-smoothstep(1.60,2.31,h));
                float viewDistance = distance(_WorldSpaceCameraPos.xyz,i.world);
                float nearFade = smoothstep(.17,1.25,viewDistance);
                float alpha = (_Density * (.055+.27*density)) * height * extent * laneDensity * outside * nearFade;
                return float4(_MistColor.rgb * lerp(.73,1.13,cloud),saturate(alpha));
            }
            ENDCG
        }
    }
}
