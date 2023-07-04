Shader "_URP/TerrainMeshBase/4 Textures"
{
    Properties
    {
        // [Note(Both Diffuse and Normal use alpha as Smoothness)]_Note("Note", Float) = 1
        // [KeywordEnum(HIGH, MEDIUM, LOW)] MATERIAL_QUALITY("Material Quality", Float) = 0
        [Note(Import NormalMap as Normal)]_Note("Note", Float) = 1
        [Toggle(_NORMALMAP)] _EnableNormal("Enable NormalMap", Float) = 1.0
        _Control("Control (RGBA)", 2D) = "red" {}
        
        [Header(Splat0)]
        [NoScaleOffset]_Splat0("Layer 0, Smoothness (A)", 2D) = "grey" {}
        [HideIfDisabled(_NORMALMAP)][NoScaleOffset]_Splat0_Normal("Normal 0 (R)", 2D) = "bump" {}
        _Splat0_S("Layer 0 Scale", Float) = 1
        _Splat0_Smoothness("Smoothness 0", Range(0.0, 1.0)) = 0.5
        
        [Header(Splat1)]
        [NoScaleOffset]_Splat1("Layer 1, Smoothness (A)", 2D) = "grey" {}
        [HideIfDisabled(_NORMALMAP)][NoScaleOffset]_Splat1_Normal("Normal 1 (G)", 2D) = "bump" {}
        _Splat1_S("Layer 1 Scale", Float) = 1
        _Splat1_Smoothness("Smoothness 1", Range(0.0, 1.0)) = 0.5
        
        [Header(Splat2)]
        [NoScaleOffset]_Splat2("Layer 2, Smoothness (A)", 2D) = "grey" {}
        [HideIfDisabled(_NORMALMAP)][NoScaleOffset]_Splat2_Normal("Normal 2 (B)", 2D) = "bump" {}
        _Splat2_S("Layer 2 Scale", Float) = 1
        _Splat2_Smoothness("Smoothness 2", Range(0.0, 1.0)) = 0.5
        
        [Header(Splat3)]
        [NoScaleOffset]_Splat3("Layer 3, Smoothness (A)", 2D) = "grey" {}
        [HideIfDisabled(_NORMALMAP)][NoScaleOffset] _Splat3_Normal("Normal 3 (A)", 2D) = "bump" {}
        _Splat3_S("Layer 3 Scale", Float) = 1
        _Splat3_Smoothness("Smoothness 3", Range(0.0, 1.0)) = 0.5
    }
    
    HLSLINCLUDE
    #define TM_3_TEX 1
    #define TM_4_TEX 1
    #define FOG_LINEAR 1
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants  _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #include "TerrainMeshLitInput.hlsl"
    ENDHLSL
    
    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False"}

        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma shader_feature _NORMALMAP

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
            //#pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma vertex LitVert
            #pragma fragment SplatmapFragment_High

            #include "TerrainMeshLitPass.hlsl"
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/TM_DepthOnly"
        UsePass "_URP/OnlyPass/LitMeta"
    }
        SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False"}

        LOD 250

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma shader_feature _NORMALMAP

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
            //#pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma vertex LitVert
            #pragma fragment SplatmapFragment_Medium

            #include "TerrainMeshLitPass.hlsl"
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/TM_DepthOnly"
        UsePass "_URP/OnlyPass/Meta"
    }
    
    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False"}

        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
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
            //#pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma vertex LitVert
            #pragma fragment SplatmapFragment_Low

            #include "TerrainMeshLitPass.hlsl"
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/TM_DepthOnly"
        UsePass "_URP/OnlyPass/VertexLitMeta"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"

}
