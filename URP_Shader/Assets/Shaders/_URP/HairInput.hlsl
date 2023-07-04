#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START (UnityPerMaterial)
float4 _BaseMap_ST;
float4 _GradientMap_ST;
//float4 _GradientMaskMap_ST;
half _Gradient_U_Speed;
half _Gradient_V_Speed;
half4 _GradientColor;

half _Cutoff;
half _Fill;
half _Intensity;
half4 _SpecColor;

half4 _EmissionColor;
half4 _PanOrPulsate;

half _SpecularShift;
half4 _SpecularTint;
half _SpecularExponent;


half _RimTransmissionIntensity;
half _AmbientReflection;

half _TranslucencyPower;
half _ShadowStrength;
half _Distortion;

half _StrandDir;

CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER (sampler_BaseMap);

TEXTURE2D (_NSMap); SAMPLER (sampler_NSMap);

TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);

TEXTURE2D(_GradientMap);       SAMPLER(sampler_GradientMap);

//TEXTURE2D(_GradientMaskMap);       SAMPLER(sampler_GradientMaskMap);
#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"
struct SurfaceData {
    half3 albedo;
    half occlusion;
    half3 normalTS;
    half smoothness;
    half metallic;
    half3 specular;
    half alpha;
    half3 emission;

    half translucency;
};

half SampleTranslucency(float2 uv) {
    half translucency = .5;
#if defined(_ALPHATEST_ON) && defined(_EMISSION) 
    SampleB(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), translucency);
    //translucency = 1;
#endif
    return translucency;
}


inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData) {
    SampleBaseMap_Hair(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    AlphaDiscard(outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);

    outSurfaceData.specular = SampleSpecular();
    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}


#endif //URP_INPUT_INCLUDED
