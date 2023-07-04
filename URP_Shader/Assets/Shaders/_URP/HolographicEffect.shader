Shader "_URP/HolographicEffect"
{
    Properties
    {
     _MainTex("Texture1", 2D) = "gray" {}
     _Texture2("BaseTexture", 2D) = "gray" {}
     _ScanSpeed("JitterSpeed", Float) = 0.2
     _Speed("Speed", Float) = 0.2
     _GlitchIntensity("GlitchIntensity ", Float) = 0.2
     _MaxRGBSplitX("MaxRGBSplitX ", Float) = 0.2
     _MaxRGBSplitY("MaxRGBSplitY ", Float) = 0.2
     _BlockSize("BlockSize(0-1)",Float)=0.5
     _Threshold("Threshold(0-1)", Float) = 0.2
     _Alpha("Alpha",float)=0.5
     _BaseColor("Base Color", Color) = (1, 1, 1, 1)
     [HDR]_FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
     _FresnelScale("Fresnel Scale", Float) = 1
     _FresnelPower("Fresnel Power", Float) = 2
     [IntRange] _StencilID("Stencil ID", Range(0,255)) = 1
     [Enum(UnityEngine.Rendering.CompareFunction)]_StencilCompMode("StencilCompMode",Float) = 3


    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent"}
        LOD 300
       /* Pass
        {
             Name "Depth Pass"
             Zwrite On
             ColorMask 0
            
             HLSLPROGRAM
             #pragma prefer_hlslcc gles
             #pragma exclude_renderers d3d11_9x
             #pragma target 2.0
             #pragma vertex vert
             #pragma fragment frag
             #include "ShaderLibrary/Lighting.hlsl"
                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;

                    float4 vertex : SV_POSITION;
                };
                float4 _MainTex_ST;
                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = TransformObjectToHClip(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _Texture0);

                    return o;
                }
                half4 frag(v2f i) : SV_Target
                {
                return 0;
                }
             ENDHLSL
        }*/
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Stencil
             {
                Ref[_StencilID]
                Comp[_StencilCompMode]

             }
            HLSLPROGRAM
           
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
           
            #include "ShaderLibrary/Lighting.hlsl"
          //  #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 uv       :TEXCOORD0;
                float3 WorldPos :TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal   :TEXCOORD2;
               
            };
            CBUFFER_START(UnityPerMaterial)
            half4 _FresnelColor;
            half4 _BaseColor;
            half _ScanSpeed, _GlitchIntensity, _Threshold, _MaxRGBSplitX, _MaxRGBSplitY, _BlockSize, _Speed;
            half _FresnelScale, _FresnelPower, _Alpha;
            CBUFFER_END
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_Texture2); SAMPLER(sampler_Texture2);

            float4 _MainTex_ST;
            float4 _Texture2_ST;



            float randomNoise(float x, float y)
            {
                return frac(sin(dot(float2(x, y), float2(12.9898, 78.233))) * 43758.5453);
            }
            float randomNoise(float2 seed)
            {
                return frac(sin(dot(seed * floor(_Time.y * _ScanSpeed), float2(17.13, 3.71))) * 43758.5453123);
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = TransformObjectToWorld(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(o.WorldPos.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(o.WorldPos.xy, _Texture2);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.vertex = TransformWorldToHClip(o.WorldPos);
             
                return o;
            }
            float4 frag(v2f i) : SV_Target
            {

             float4 finalcolor = 0;
             float4 tex = SAMPLE_TEXTURE2D(_Texture2,sampler_Texture2, i.uv.zw+ _Time.x* _Speed);
             finalcolor += tex;
             half  strength = 0.5 + 0.5 * cos(_Time.y * _ScanSpeed);
            //------扫描线故障-------------------------
            float jitter = randomNoise(i.uv.y, _Time.x) * 2 - 1;  
            jitter *= step(_Threshold, abs(jitter)) * _GlitchIntensity * strength;
            float4 tex1 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, frac(i.uv + float2(jitter, 0)));
           
            finalcolor += tex1;
            //------Image Block Glitch+RGB通道分离-------------------------

            half2 block = randomNoise(floor(i.uv * _BlockSize));

            float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);
            float splitRGBNoise = pow(randomNoise(7.2341), 17.0);
            float offsetX = displaceNoise - splitRGBNoise * _MaxRGBSplitX;
            float offsetY = displaceNoise - splitRGBNoise * _MaxRGBSplitY;

            float noiseX = 0.05 * randomNoise(13.0);
            float noiseY = 0.05 * randomNoise(7.0);
            float2 offset = float2(offsetX * noiseX, offsetY * noiseY);

            half4 colorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
            half4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset);
            half4 colorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - offset);

            half4 glitcolor= half4(colorR.r, colorG.g, colorB.b, frac(colorR.a + colorG.a + colorB.a));
            //-----------菲涅尔---------------------
            float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.WorldPos.xyz);
            float NDotV = dot(i.normal, viewDir);
            float rim = 1.0 - NDotV;
            float4 fresnel= _FresnelScale * pow(rim, _FresnelPower);
            fresnel.a = clamp(fresnel.a, 0.0, 1.0);
            float4 FresnelCol = float4(fresnel.rgb, 1.0) * float4(_FresnelColor.rgb, 1.0) * fresnel.a+ _BaseColor* NDotV;
            finalcolor.rgb += FresnelCol.rgb;
          
            return lerp(finalcolor + glitcolor, glitcolor* finalcolor, 1-_Alpha);
            }
            ENDHLSL
        }
    }
}
