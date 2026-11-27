Shader "Scene/Perimeter Fog"
{
    Properties
    {
        _FogCenter ("Circle Center (X, Z)", Vector) = (3,-4,0,0)
        _Radius ("Clear Radius", Range(12,45)) = 27
        _FogColor ("Fog Color", Color) = (.195,.168,.226,1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent-20" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Cull Front
        ZWrite Off
        ZTest Always
        Blend One OneMinusSrcAlpha
        Pass
        {
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _FogCenter, _FogColor;
                float _Radius;
            CBUFFER_END

            struct Attributes
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float4 position : SV_POSITION;
                float3 world : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.position = TransformObjectToHClip(v.vertex.xyz);
                o.world = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            float Hash(float2 p)
            {
                float3 q = frac(p.xyx*float3(.1031,.11369,.13787));
                q += dot(q,q.yzx+19.19);
                return frac((q.x+q.y)*q.z);
            }

            float Noise(float2 p)
            {
                float2 c = floor(p), f = frac(p);
                f = f*f*(3-2*f);
                return lerp(lerp(Hash(c),Hash(c+float2(1,0)),f.x),
                            lerp(Hash(c+float2(0,1)),Hash(c+1),f.x),f.y);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                const float domeBase = 1.0;
                const float domeHeight = 25.0;
                const int samples = 28;
                float3 origin = GetCameraPositionWS();
                float3 ray = normalize(i.world-origin);

                // Stop the march at the first opaque surface, including the ground and facade.
                float2 screenUV = GetNormalizedScreenSpaceUV(i.position);
                float depth = SampleSceneDepth(screenUV);
                float viewCosine = max(.015,-TransformWorldToViewDir(ray).z);
                float depthDistance = LinearEyeDepth(depth,_ZBufferParams)/viewCosine;
                float marchLength = min(min(length(i.world-origin),depthDistance),72.0);
                float stepLength = marchLength/samples;

                float3 moonDirection = normalize(float3(-.301,.545,.783));
                float moonFacing = saturate(dot(ray,moonDirection));
                float moonHalo = pow(moonFacing,26);
                float moonWindow = smoothstep(.947,.988,moonFacing)*smoothstep(.10,.36,ray.y);
                float3 accumulated = 0;
                float transmittance = 1;
                float time = _Time.y;
                float2 drift = time*float2(.13,-.075);
                float offset = lerp(.45,.55,Hash(floor(i.position.xy)));
                [loop]
                for (int s=0;s<samples;s++)
                {
                    float3 p = origin+ray*((s+offset)*stepLength);
                    float2 xz = p.xz-_FogCenter.xy;
                    float2 flow = p.xz-drift+p.y*float2(.87,-.48);
                    float banks = Noise(flow*.105+16);
                    float wisps = Noise((flow+float2(-p.y*.57,p.y*.72))*.29-drift*.57+31);
                    float height = max(0,p.y-domeBase)/domeHeight;
                    float radius = length(xz)/_Radius;
                    float surface = length(float2(radius,height))+(banks-.5)*.16+(wisps-.5)*.075;
                    float volume = 1-smoothstep(1.20,1.44,surface);

                    float2 fromDoor = p.xz-float2(6.1,-6.1);
                    float along = dot(fromDoor,float2(.707107,-.707107));
                    float across = abs(dot(fromDoor,float2(.707107,.707107)));
                    float lane = (1-smoothstep(.75,2.75,across+(wisps-.5)*.40))
                        * smoothstep(-.7,.4,along)*(1-smoothstep(23,33,along))
                        * (1-smoothstep(1.0,4.1,p.y));
                    float wave = sin(p.y*.85+banks*4.7+wisps*1.7-time*.32);
                    float groundFog = exp(-max(p.y,0)*.44)
                        * lerp(.032,.15,smoothstep(.18,.82,banks*.70+wisps*.30));
                    float thinHaze = .0035 + .014*wisps*banks*(.64+.36*wave);
                    float insideDensity = (groundFog*lerp(1,.13,lane)+thinHaze)*volume;

                    float shell = smoothstep(.78,.98,surface)*(1-smoothstep(1.04,1.37,surface));
                    float shoulder = smoothstep(.13,.60,height);
                    float canopy = shell*lerp(.16,.026,shoulder)*lerp(.65,1.45,banks);
                    float skirt = smoothstep(.83,1.09,radius+(banks-.5)*.15)
                        * (1-smoothstep(2.0,9.8+3.2*banks,p.y))
                        * (.15+.16*banks+.09*wisps);

                    float density = (insideDensity+canopy+skirt)*lerp(1,.17,moonWindow);
                    float opacity = 1-exp(-density*stepLength);
                    float3 tint = _FogColor.rgb * (.74+.43*banks+.12*wisps)
                        + moonHalo*float3(.0060,.0044,.0080);
                    accumulated += transmittance*opacity*tint;
                    transmittance *= 1-opacity;
                }
                return float4(accumulated,1-transmittance);
            }
            ENDHLSL
        }
    }
}
