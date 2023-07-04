Shader "_URP/Glass"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        
        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5
        // [HideInInspector] _Surface("__surface", Float) = 0.0   
        // [HideInInspector] _Blend("__blend", Float) = 0.0 
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "gray" {}
        [NoScaleOffset] _NSMap("Normal Map (RGB), Smoothness(A)", 2D) = "gray" {}

        [Header(Reflection)]
        _Cubemap("Environment Cubemap", Cube) = "_Skybox"{}
        
        [Header(Refraction)]
        _EnableOpaqueTexture ("Enable Opaque Texture", Float) = 1.0
        _Distortion("Distortion", Range(0, 100)) = 10
        _RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0
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
        */
       // _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
       // _Smoothness("Smoothness", Float) = 0.5
        
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
    
    HLSLINCLUDE
    
    #ifndef URP_INPUT_INCLUDED
    #define URP_INPUT_INCLUDED
    
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE 
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX

    #define _ENV 1
    #define FOG_LINEAR 1
    #define _SPECULAR_SETUP 1
    
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
    
    #define _CUTOFF_OR_TRANSUV 1
    
    CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half4 _SpecColor;
    half _Cutoff;
    
    half _Distortion;
    half _RefractAmount;
    CBUFFER_END
    
    half4 _CameraOpaqueTexture_TexelSize;
    
    TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
    TEXTURE2D(_NSMap);              SAMPLER(sampler_NSMap);
    TEXTURECUBE(_Cubemap);          SAMPLER(sampler_Cubemap);
    #if defined(_OPAQUETEX)
    TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture_linear_clamp);
    #endif
    
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
        
        outSurfaceData.metallic = 0;
        half emissionMask = 1;
        outSurfaceData.emission = 0;
        outSurfaceData.albedo = LerpPattern(uv, saturate(outSurfaceData.alpha * (1-emissionMask)), outSurfaceData.albedo);
        outSurfaceData.specular = SampleSpecular();
    }
    
    #endif //URP_INPUT_INCLUDED
    
    ENDHLSL
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 250
        Cull [_Cull]
        Blend [_SrcBlend][_DstBlend]
        ZWrite[_ZWrite]
        
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
            // Material Keywords
            /*
            #pragma shader_feature_local _EMISSION
            #if defined (_Emission)
            #pragma shader_feature_local _PAN
            #endif
            */

            #pragma shader_feature _OPAQUETEX
            
            #pragma shader_feature _NORMALMAP
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
            
            #include "GlassForwardPass.hlsl"

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
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 200
        
        Cull [_Cull]
        Blend [_SrcBlend][_DstBlend]
        ZWrite[_ZWrite]
        
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
            // Material Keywords

            #pragma shader_feature _OPAQUETEX
            
            #pragma shader_feature _NORMALMAP
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
    CustomEditor "URP.Editor.GlassShaderGUI"
}
