Shader "Scene/Moonlit Sky"
{
    Properties { _MoonDirection ("Moon Direction", Vector) = (-.301,.545,.783,0) }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            float4 _MoonDirection;
            struct Varyings { float4 position : SV_POSITION; float3 ray : TEXCOORD0; };
            Varyings Vert(float4 vertex : POSITION)
            {
                Varyings o;
                o.position = UnityObjectToClipPos(vertex);
                o.ray = mul((float3x3)unity_ObjectToWorld, vertex.xyz);
                return o;
            }
            float Hash(float2 p)
            {
                float3 q = frac(p.xyx * float3(.1031,.11369,.13787));
                q += dot(q, q.yzx + 19.19);
                return frac((q.x + q.y) * q.z);
            }
            float Noise(float2 p)
            {
                float2 i = floor(p), t = frac(p);
                t = t*t*(3-2*t);
                return lerp(lerp(Hash(i), Hash(i+float2(1,0)), t.x),
                            lerp(Hash(i+float2(0,1)), Hash(i+1), t.x), t.y);
            }
            float4 Frag(Varyings i) : SV_Target
            {
                float3 ray = normalize(i.ray);
                float3 sky = lerp(float3(.00075,.00103,.0020), float3(.0045,.0058,.0088), exp(-abs(ray.y)*6));
                float2 grid = (float2(atan2(ray.x,ray.z)/6.283185, asin(ray.y)/3.141593)+.5)*float2(280,140);
                float2 cell = floor(grid);
                float2 starCenter = .22+.56*float2(Hash(cell+27),Hash(cell+101));
                float star = (1-smoothstep(.022,.11,length(frac(grid)-starCenter))) * step(.958,Hash(cell));
                sky += star*.14*Hash(cell+62)*smoothstep(.025,.22,ray.y)*float3(.76,.85,1);
                float3 moon = normalize(_MoonDirection.xyz);
                float3 right = normalize(cross(float3(0,1,0),moon));
                float3 up = cross(moon,right);
                float facing = dot(ray,moon);
                float2 disc = float2(dot(ray,right),dot(ray,up))/max(.01,facing)/.166;
                float radius = length(disc);
                float edge = clamp(fwidth(radius),.008,.11);
                float coverage = (1-smoothstep(1-edge,1+edge,radius))*step(0,facing);
                float glow = .014*exp(-(1-facing)*58)+.0035*exp(-(1-facing)*23);
                sky += glow*float3(.48,.65,1);
                float maria = .58*Noise(disc*2.8+17)+.29*Noise(disc*6.2+31)+.13*Noise(disc*21+48);
                float albedo = .91-.42*smoothstep(.30,.69,maria);
                float crater = length(disc-float2(-.36,-.5))/.17;
                albedo += .13*(1-smoothstep(.04,.21,abs(crater-.86)))-.17*(1-smoothstep(.45,.88,crater));
                float limb = .66+.34*sqrt(saturate(1-radius*radius));
                return float4(lerp(sky,float3(1,.96,.86)*albedo*limb*1.42,coverage),1);
            }
            ENDCG
        }
    }
}
