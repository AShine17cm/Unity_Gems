Shader "_URP/Custom/Map"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        
        // BlendMode
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Cull [_Cull]
        
        HLSLINCLUDE
        
        #define _CUTOFF_OR_TRANSUV 1
        #define FOG_LINEAR 1
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half _Cutoff;
        half4 _BaseColor;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Name "PassTest"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_instancing
            
            #include "ShaderLibrary/BaseSampling.hlsl"
            #include "ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;   
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 lambertAndFogFactor      : TEXCOORD1;        
                float4 positionCS    : SV_POSITION;
                
                #ifdef LIGHTMAP_ON
                float2 lightmapUV               : TEXCOORD2;
                #endif
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float4 positionCS = TransformWorldToHClip(positionWS);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                
                half4 shadowCoord = float4(0, 0, 0, 0);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    shadowCoord = TransformWorldToShadowCoord(positionWS);
                #endif
                
                half3 bakedGI = 0;
                #ifdef LIGHTMAP_ON
                output.lightmapUV = input.lightmapUV;
                #else
                bakedGI = SampleSHVertex(normalWS);
                #endif            
                    
                /*#if defined(UNITY_REVERSED_Z)
                float fog = 1 - log(positionCS.w + 1) / 9.210441;
                #else
                float fog = log(positionCS.w + 1) / 9.210441;
                #endif*/
                output.positionCS = positionCS;
                output.lambertAndFogFactor.rgb = Lambert(1, normalWS, positionWS, shadowCoord, bakedGI, 0);
                output.lambertAndFogFactor.a = 0.47;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half alpha = texColor.a;
                AlphaDiscard(alpha);
                
    half4 color = VertexLitLighting(input.lambertAndFogFactor, texColor.rgb, 0, 1, alpha
#ifdef LIGHTMAP_ON
        ,input.lightmapUV
#endif
);
                return color;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.UnlitShaderGUI"
}
