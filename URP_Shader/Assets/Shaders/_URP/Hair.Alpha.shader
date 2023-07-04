Shader "_URP/Hair.Alpha"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0

        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        _RenderSide ("__Render_Side",Float) = 1.0
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion(A)", 2D) = "white" {}
        //_EnableMaskMap ("Enable Mask Map", Float) = 0.0
        [NoScaleOffset] _NSMap("Normal Map(RGB), Shift(A)", 2D) = "gray" {}
        [NoScaleOffset]  _EmissionMap("Emission(B) Noise(A)", 2D) = "white" {}
        [Header(Emission)]
        _EmissionEnabled("__emission", Float) = 0.0
        [HDR]
        _EmissionColor ("Emission Color", Color) = (1, 1, 0, 0) 
        // Editor Field will add to _EmissionColor.a;
        _EmissionPower ("Emission Power", Range(0, 5)) = 1
        
        [Space]
        _PanOrPulsateEmission ("Pan Or Pulsate", Float ) = 0 
        _PanOrPulsate ("Pan: Tiling(xy) Speed(zw); Pulse: Speed(x), Power Range(yz), Color Variant(a)", Vector) = (1, 1, .5, 0)
        
        _SpecColor                  ("Specular", Color) = (0.2, 0.2, 0.2)
        _Smoothness                 ("Smoothness", Range(0.0, 1.0)) = 1

        [KeywordEnum(Bitangent,Tangent)]
        _StrandDir  ("Strand Direction", Float) = 0
        _SpecularShift              ("Primary Specular Shift", Range(-1.0, 1.0)) = 0.1
        [HDR] _SpecularTint         ("Primary Specular Tint", Color) = (1, 1, 1, 1)
        _SpecularExponent           ("Primary Smoothness", Range(0.0, 1)) = .85
        
        _RimTransmissionIntensity   ("Rim Transmission Intensity", Range(0.0, 1.0)) = 0.5
        _AmbientReflection          ("Ambient Reflection Strength", Range(0.0, 1.0)) = 1
        [Header(Transmission)]
        _TranslucencyPower          ("Translucency Power", Range(0.0, 1.0)) = 1
        _ShadowStrength          ("Shadow Strength", Range(0.0, 1.0)) = 1
        _Distortion          ("Distortion", Range(0.0, 1.0)) = 1
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
        
    HLSLINCLUDE
    #define _SPECULAR_SETUP 1
    #define FOG_LINEAR 1
    #define _NORMALMAP 1
    #define _MASKMAP 1
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    
    #include "HairInput.hlsl"
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent"}
        LOD 300

        Pass
        {
            Name "ZOnly"
            Tags {"LightMode" = "PreForward"}
            ZWrite On
            ColorMask 0
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite Off
            Blend [_SrcBlend][_DstBlend]
            
            //ZWrite[_ZWrite]
            //ZTest Less
            Cull [_Cull]
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
  
            #pragma shader_feature_local _EMISSION
            
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            //#pragma shader_feature_local _MASKMAP
            #pragma shader_feature _VFACE
            
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma vertex LitVert
            
            #pragma fragment LitFrag
            
            #include "HairLitPass.hlsl"
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
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent"}
        LOD 250

        Pass
        {
            Name "ZOnly"
            Tags {"LightMode" = "PreForward"}
            ZWrite On
            ColorMask 0
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend [_SrcBlend][_DstBlend]
            ZWrite Off
            //ZWrite[_ZWrite]
            //ZTest Less
            Cull [_Cull]
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            
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
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent"}
        LOD 200

        Pass
        {
            Name "ZOnly"
            Tags {"LightMode" = "PreForward"}
            ZWrite On
            ColorMask 0
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend [_SrcBlend][_DstBlend]
            //ZWrite[_ZWrite]
            ZWrite Off
            //ZTest Less
            Cull [_Cull]
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
             
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            
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
            #pragma vertex LitVert
            
            #pragma fragment LitFrag
            
            #include "LambertLitPass.hlsl"
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
    
    CustomEditor "URP.Editor.HairShaderGUI"
}
