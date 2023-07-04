﻿Shader "_URP/Lit_Furry"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0

        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "gray" {}
        [NoScaleOffset] _NSMap("Normal Map (RGB), Smoothness(A)", 2D) = "gray" {}
        _LayerTex("Layer", 2D) = "gray" {}
        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _Smoothness("Smoothness", Float) = 0.5

        [Header(Fur)]
        _FurLength("Fur Length", Range(.0002, 1)) = .25
        _MaskSmooth("MaskSmooth",Range(0, 0.5))=0
        _NoiseScale("Noise scale",Range(1,100)) = 10
		_CutoffEnd("Alpha Cutoff end", Range(0,1)) = 0.5 // how thick they are at the end
		_EdgeFade("Edge Fade", Range(0,1)) = 0.4
		_Gravity("Gravity Direction", Vector) = (0,-1,0,0)
		_GravityStrength("Gravity Strength", Range(0,1)) = 0.25
		_FabricScatterColor("Fabric Scatter Color", Color) = (1,1,1,1)
		_FabricScatterScale("Fabric Scatter Scale", Range(0, 1)) = 0
		_ShadowColor("Shadow Color",Color)=(0,0,0,0)
        _ShadowAO("Shadow AO",Range(0,1))=1
        _UVOffset("UVOffset",Vector)=(0,0,0.2,0.2)       
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
        
        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
        
    HLSLINCLUDE
    // #define FOG_LINEAR 1
    #define _NORMALMAP 1
    #define _SPECULAR_SETUP 1
    
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #include "LitInput_Furry.hlsl"
    ENDHLSL
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300
        
         Pass
        {
            Name "FurRender"
            Tags { "LightMode" = "FurRendererBase" }
           // Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma shader_feature _ _TANGENT_TO_WORLD
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
            
            #include "LitForwardPass_Furry.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "FurLayer"
            Tags { "LightMode" = "FurRendererLayer" }
            
            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
            //#pragma shader_feature_local _EMISSION
            //#if defined (_Emission)
            //#pragma shader_feature_local _PAN
            //#endif
            
          // #pragma shader_feature_local _FUR 
   

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
            
            #include "LitForwardPass_Furry.hlsl"
            ENDHLSL
        }
         
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/LitMeta"
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 250

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "FurRendererBase" }
            
           // Cull[_Cull]
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
            //#pragma shader_feature_local _EMISSION
            //#if defined (_Emission)
            //#pragma shader_feature_local _PAN
            //#endif
            
            //#pragma shader_feature_local _PATTERNMAP
            
            // #pragma shader_feature _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
                   
            #include "SimpleLitForwardPass_Fur.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "FurRendererLayer" }
            
            //Cull[_Cull]
             Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
            //#pragma shader_feature_local _EMISSION
            //#if defined (_Emission)
            //#pragma shader_feature_local _PAN
            //#endif
            
            //#pragma shader_feature_local _PATTERNMAP
            
            // #pragma shader_feature _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
                   
            #include "SimpleLitForwardPass_Fur.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/Meta"
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 200
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "FurRendererBase" }
            
            Cull[_Cull]
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            // #pragma multi_compile MATERIAL_QUALITY_MEDIUM MATERIAL_QUALITY_LOW
            
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            #pragma shader_feature_local _PATTERNMAP
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF 
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
      
            #include "LambertLitPass_Fur.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "FurRendererLayer" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull[_Cull]
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            // #pragma multi_compile MATERIAL_QUALITY_MEDIUM MATERIAL_QUALITY_LOW
            
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            #pragma shader_feature_local _PATTERNMAP
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF 
            
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
            #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex LitVert_LayerBase
            #pragma fragment LitFrag_LayerBase
      
            #include "LambertLitPass_Fur.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/VertexLitMeta"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.FurShaderGUI"
}
