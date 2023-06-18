Shader "m1Ra/OutLIne_Glitch"
{
    Properties
    {
       _Clip("clip",range(0,1)) = 0.2
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
        LOD 300

        Pass
        {
           Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma shader_feature_local _SON  

            #pragma vertex vert  
            #pragma fragment frag  

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            float4 _BaseColor;
            float _Speed;
            float _Clip;
            float _Offset;
            float _SmallOffset;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
               float3 normal : NORMAL;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 ScreenPos : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };
            float RandomRange(float Min, float Max,float2 Seed)
            {
                float alpha = frac(sin(dot(Seed,float2(12.9898,78.233))) * 43758.55);
                alpha = frac(alpha);
                return lerp(Min,Max,alpha);
            }
            float4 Posterize(float4 In, float4 Steps)
            {
                return floor(In / (1 / Steps)) * (1 / Steps);
            }
            float2 gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
float gradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(gradientNoise_dir(ip), fp);
    float d01 = dot(gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
    }
    float GradientNoise(float2 UV, float Scale)
    {
        return gradientNoise(UV * Scale) + 0.5;
    }
   v2f vert(appdata v)
   {
       v2f o;
        float3 posWS = TransformObjectToWorld(v.vertex).xyz;
        // lines  
        float time_y = floor(_Time.y * 8 * _Speed);
        float lines = RandomRange(0,0.4,Posterize(posWS.y + time_y,5));

        //panning sine wave  
        float p = sin(posWS.r * posWS.b * 5 + _Time.y * 5 * _Speed);
        float sinwave = frac(p * 2) * 0.2 + 0.1;
        // float wave = saturate(p - 0.7);  

         float d = sinwave * lines * _Offset;

        #if defined(_SON)  
         // push vertex with normal vector  
         float3 vertex_offset = v.vertex.xyz + d * 0.5 * v.normal;
        #else  
         // Scale vertex pos  
         float3 vertex_offset = v.vertex.xyz + d * v.vertex.xyz;
        #endif  

         // small random offset  
         float3 posOS_offset = floor(_Time.y * 8 * _Speed) + v.vertex.xyz;
         float3 small_offset = RandomRange(-0.5,0.5,posOS_offset.xy) * 0.04 * _SmallOffset;

         v.vertex.xyz = small_offset + vertex_offset;
                         o.vertex = TransformObjectToHClip(v.vertex.xyz);
         o.positionWS = TransformObjectToWorld(v.vertex);
         o.ScreenPos = ComputeScreenPos(o.vertex);
         o.uv = v.uv;
         return o;
        }
    half4 frag(v2f i) : SV_Target
    {
        // Value  
        float2 ScreenUV = i.ScreenPos.xy / i.ScreenPos.w;;
        float3 positionWS = i.positionWS;

        // panning sine wave  
        float p = sin(positionWS.r * positionWS.b * 5 + _Time.y * 5 * _Speed);
        p = saturate(p) * 0.5;
        float4 color = p + _BaseColor;

        // alpha  
        //lines                
        float l = ScreenUV.y + floor(_Time * 10 * _Speed);
        float randomline = RandomRange(0,2,Posterize(l,800));
        float2 noise_uv = ScreenUV - float2(randomline,0);
        float noise = GradientNoise(noise_uv , 5) - 0.5;
        noise *= 0.1;

       // distort screen pos  
       float2 screenpos_distort = float2(ScreenUV + noise / i.ScreenPos.w);

       float scene_depth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenpos_distort),_ZBufferParams);

       float alpha = scene_depth - i.ScreenPos.w;
        alpha = saturate(alpha) + 0.08;

        clip(alpha - _Clip);
        return float4(color.rgb, 1);
    }            
    ENDHLSL
    }
}}