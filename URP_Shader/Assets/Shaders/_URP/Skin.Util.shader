Shader "_URP/Skin Util"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0

        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "white" {}
        _EnableMaskMap ("Enable Mask Map", Float) = 0.0
        [NoScaleOffset] _NSMap("Normal Map (RGB), Smoothness(A)", 2D) = "gray" {}
        
        [NoScaleOffset]  _EmissionMap("Thickness(G) Emission(B) Noise(A)", 2D) = "black" {}
        [Header(Emission)]
        _EmissionEnabled("__emission", Float) = 0.0
        [HDR]
        _EmissionColor ("Emission Color", Color) = (1, 1, 0, 0) 
        // Editor Field will add to _EmissionColor.a;
        _EmissionPower ("Emission Power", Range(0, 5)) = 1
        _PanOrPulsateEmission ("Pan Or Pulsate", Float ) = 0 
        _PanOrPulsate ("Pan: Tiling(xy) Speed(zw); Pulse: Speed(x), Power Range(yz), Color Variant(a)", Vector) = (1, 1, .5, 0)
        
        _ColorMode ("Skin Color Change Mode", Float) = 0
        _ChangeColor ("Skin Color", Color) = (1, 1, 1,0)
        
        _SpecColor ("Specular", Color) = (0.2, 0.2, 0.2)
        _Smoothness("Smoothness", Float) = 0.5
        
        [NoScaleOffset] _LUTMap("Lut Map(RGB)", 2D) = "gray" {}
        _lightPower("lightPower",Range(1,2))=1.5
        _addSkinColor("AddSkinColor",Color)=(0.6594,0.1429,0.6314)
        _SubsurfaceColor            ("Subsurface Color", Color) = (1.0, 0.4, 0.25, 1.0)
        _TranslucencyPower          ("Transmission Power", Range(0.0, 10.0)) = 7.0
        _ShadowStrength             ("Shadow Strength", Range(0.0, 1.0)) = 0.7
        _Distortion                 ("Transmission Distortion", Range(0.0, 0.1)) = 0.01

        // Unity Features
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
    
    HLSLINCLUDE
                
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #define _SPECULAR_SETUP 1
    #define _NORMALMAP 1
    #define FOG_LINEAR 1
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
    
    #define _CUTOFF_OR_TRANSUV 1
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half4 _SpecColor;
        
        half4 _EmissionColor;
        half4 _PanOrPulsate;
        
        half  _lightPower;
        
        half3  _addSkinColor;
        half4 _ChangeColor;
        half3 _SubsurfaceColor;
        half _TranslucencyPower;
        half _ShadowStrength;
        half _Distortion;
        CBUFFER_END
        
        TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);
        TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);
        
        #include "ShaderLibrary/VFX.hlsl"
        #include "ShaderLibrary/Sampling.hlsl"

        struct SurfaceData
        {
            half3 albedo;
            half  occlusion;
            half3 normalTS;
            half  smoothness;
            half  metallic;
            half3 emission;
            half3 specular;
            half  alpha;
        };


        inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
        {
            SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
            
            AlphaDiscard(outSurfaceData.alpha);
            SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
            
            outSurfaceData.metallic = SampleMetallic(uv);
            half emissionMask;
            outSurfaceData.emission = SampleEmissionMask(uv, emissionMask);
            outSurfaceData.albedo = LerpPattern(uv, saturate(outSurfaceData.alpha * (1 - emissionMask)), outSurfaceData.albedo);
            outSurfaceData.specular = SampleSpecular();
        }

        TEXTURE2D(_LUTMap);          SAMPLER(sampler_LUTMap);

    ENDHLSL      
        
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300
         
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            //  Shader target needs to be 3.0 due to tex2Dlod in the vertex shader and VFACE
            #pragma target 3.0
            
            // -------------------------------------
            // Material Keywords

            #define _SCATTERING 1

            
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
           
            #pragma shader_feature_local _COLOR_SOFTLIGHT
            
            // #pragma shader_feature _NORMALMAP
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
            
            #include "SkinLitPass.hlsl"
            
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
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
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            //  Shader target needs to be 3.0 due to tex2Dlod in the vertex shader and VFACE
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords

            #pragma shader_feature_local _MASKMAP
            
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _COLOR_SOFTLIGHT
            
            // #pragma shader_feature _NORMALMAP
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
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
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
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            //  Shader target needs to be 3.0 due to tex2Dlod in the vertex shader and VFACE
            #pragma target 3.0
            
            // -------------------------------------
            // Material Keywords
            
            #pragma shader_feature_local _MASKMAP
            
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            
            #pragma shader_feature_local _COLOR_SOFTLIGHT
            
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
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/VertexLitMeta"
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.SkinShaderGUI"
}
