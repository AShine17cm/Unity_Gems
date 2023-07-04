﻿Shader "_URP/Foliage/Billboard"
{
    Properties
    {
        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "white" {}
        
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        
        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
    }
    
    HLSLINCLUDE
    #define _ENV 1
    #define FOG_LINEAR 1
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE 
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #include "BillboardInput.hlsl"
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull[_Cull]
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature_local _ALPHATEST_ON

            #pragma vertex LitVert
            #pragma fragment LitFrag

            #include "BillboardLitPass.hlsl"
            
            ENDHLSL
        }
        
      UsePass "_URP/OnlyPass/TM_ShadowCaster"
      // UsePass "_URP/OnlyPass/TM_DepthOnly"
       UsePass "_URP/OnlyPass/UnlitMeta"
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.SimpleLitShaderGUI"
}
