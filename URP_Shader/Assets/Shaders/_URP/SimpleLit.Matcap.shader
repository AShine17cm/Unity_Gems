Shader "_URP/SimpleLit.Matcap"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0
        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "gray" {}
        [MainTexture] _MatcapMap("Matcap Map (RGB)", 2D) = "gray" {}

        [NoScaleOffset] _NSMap("Normal Map (RGB), Smoothness(A)", 2D) = "gray" {}

        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _Smoothness("Smoothness", Float) = 0.5
        _BaseMapAlphaAsSmoothness("BaseMap Alpha As Smoothness", Float) = 0.0
        
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        /*
        [NoScaleOffset]  _EmissionMap("Metallic(G) Emission(B) Noise(A)", 2D) = "gray" {}
        [Header(Emission)]
        _EmissionEnabled("__emission", Float) = 0.0
        [HDR]
        _EmissionColor ("Emission Color", Color) = (1, 1, 0, 0) 
        _EmissionPower ("Emission Power", Range(0, 5)) = 1
        [Space]
        _PanOrPulsateEmission ("Pan Or Pulsate", Float ) = 0 
        _PanOrPulsate ("Pan: Tiling(xy) Speed(zw); Pulse: Speed(x), Power Range(yz), Color Variant(a)", Vector) = (1, 1, .5, 0)
        [Header(Pattern)]
        _EnablePattern("__pattern", Float) = 0.0
        _PatternMap("Pattern Map, Smoothness(A)", 2D) = "white" {}
        */
    }
    
    HLSLINCLUDE   
    #define _SPECULAR_SETUP 1
    #define _ENV 1
    #define FOG_LINEAR 1

    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    ENDHLSL  
      
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 250
        HLSLINCLUDE   
        #define _MATCAP 1
        #define _NORMALMAP 1
        #include "SimpleLitInput.hlsl"
                    
        ENDHLSL
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
            /*
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _PATTERNMAP
            */
            
            // #pragma shader_feature _NORMALMAP
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
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitVert
            #pragma fragment LitFrag

            #include "SimpleLitForwardPass.hlsl"
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
            #pragma multi_compile_instancing

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
        HLSLINCLUDE   
        #include "SimpleLitInput.hlsl"
        ENDHLSL
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
            /*
            #pragma shader_feature_local _EMISSION
            
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _PATTERNMAP
            */
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
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitVert
            #pragma fragment LitFrag

            #include "VertexLitPass.hlsl"
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
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/VertexLitMeta"
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.SimpleLitShaderGUI"
}
