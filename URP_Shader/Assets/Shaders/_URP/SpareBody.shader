Shader "_URP/SpareBody"
{
    Properties
    {
     _BaseMap("Texture", 2D) = "white" {}
     [HDR]_BaseColor("Base Color", Color) = (1, 1, 1, 1)
     [HDR]_FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
     _FresnelScale("Fresnel Scale", Float) = 1
     _FresnelPower("Fresnel Power", Float) = 2
     _UVSpeed("UVSpeed", Float) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 300
    
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
       
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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv       :TEXCOORD0;
                float3 WorldPos :TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal   :TEXCOORD2;
               
            };
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
            half4 _FresnelColor;
            half4 _BaseColor;
            half _FresnelScale, _FresnelPower, _UVSpeed;
            float4 _BaseMap_ST;
            CBUFFER_END
          
            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = TransformObjectToWorld(v.vertex.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.vertex = TransformWorldToHClip(o.WorldPos);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }
            float4 frag(v2f i) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv + _Time.x * _UVSpeed);
                half4 finalcolor = texColor *_BaseColor;
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.WorldPos.xyz);
                float NDotV = dot(i.normal, viewDir);
                float rim = 1.0 - NDotV;
                float4 fresnel= _FresnelScale * pow(rim, _FresnelPower)* _FresnelColor;
                finalcolor.rgb += fresnel;
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
