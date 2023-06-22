Shader "m1Ra/Blit_Glitch"
{
    Properties
    {
    }    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
        LOD 300

        Pass
        {
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert  
            #pragma fragment frag  

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  

            TEXTURE2D(_TempGlitch);        SAMPLER(sampler_TempGlitch);
            float _Intensity;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 ScreenPos : TEXCOORD1;
            };
            float RandomRange(float Min, float Max,float2 Seed)
            {
                float alpha = sin(dot(Seed,float2(12.9898,78.233))) * 43758.55;
                alpha = frac(alpha);
                return lerp(Min,Max,alpha);
            }
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.ScreenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }
            half4 frag(v2f i) : SV_Target
            {
                // Value  
                float2 ScreenUV = i.ScreenPos.xy / i.ScreenPos.w;;
                float2 uv = i.uv;
                // Random flicker  
                float2 speed = floor(_Time.y * 10);
                float random1 = RandomRange(-2,1,speed);
                random1 = saturate(random1);
                float random2 = RangeRemap(0.5,2,speed);
                float random = random1 * random2;
                float random_flick = (random + 0.5) * 0.008;

                // mask  
                float mask_dir = normalize(ScreenUV);
                // float mask = distance(ScreenUV,half2(0.5,0.5));  
                float mask = distance(ScreenUV,half2(0,0));
                mask = smoothstep(0.2,1,mask) * mask_dir;
                float offset = random_flick * mask * _Intensity;

                // chromatic aberration  
                float2 uv_r = uv + offset;
                float2 uv_g = uv;
                float2 uv_b = uv - offset;

                float Var_Maintex_R = SAMPLE_TEXTURE2D(_TempGlitch,sampler_TempGlitch,uv_r).r;
                float Var_Maintex_G = SAMPLE_TEXTURE2D(_TempGlitch,sampler_TempGlitch,uv_g).g;
                float Var_Maintex_B = SAMPLE_TEXTURE2D(_TempGlitch,sampler_TempGlitch,uv_b).b;
                float3 color = float3(Var_Maintex_R,Var_Maintex_G,Var_Maintex_B);
                return float4(color,1);
            }            
            ENDHLSL
        }
    }
}