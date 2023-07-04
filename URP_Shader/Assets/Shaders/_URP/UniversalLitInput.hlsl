#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1 

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half4 _SpecColor;
half4 _EmissionColor;
half4 _PanOrPulsate;

//hair
half _Fill;
half _Intensity;
float4 _GradientMap_ST;
half _Gradient_U_Speed;
half _Gradient_V_Speed;
half4 _GradientColor;
half _SpecularShift;
half4 _SpecularTint;
half _SpecularExponent;
half _RimTransmissionIntensity;
half _AmbientReflection;
half _TranslucencyPower;
half _ShadowStrength;
half _Distortion;
half _StrandDir;
//half3 _SubsurfaceColor;
//skin
half  _lightPower;
half4 _ChangeColor;
half3  _addSkinColor;
//half3 _RimColor;
//half  _RimWidth;
//half _RimIntensity;
//half _RimSmoothness;

CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);

TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);

TEXTURE2D(_GradientMap);       SAMPLER(sampler_GradientMap);


TEXTURE2D(_LUTMap);          SAMPLER(sampler_LUTMap);

#if defined(_PATTERNMAP)
TEXTURE2D(_PatternMap);       SAMPLER(sampler_PatternMap);
#endif

#define _CUTOFF_OR_TRANSUV 1

#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"
#include "ShaderLibrary/Util.hlsl"
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
#if defined(_ENABLE_HAIR)
    half translucency;
#endif


};


half SampleTranslucency(float2 uv) {
    half translucency = .5;
#if defined(_ALPHATEST_ON) && defined(_EMISSION) 
    SampleB(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), translucency);
    //translucency = 1;
#endif
    return translucency;
}

inline void InitializeSurfaceDataPBR(float2 uv, out SurfaceData outSurfaceData)
{
    SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    SampleNormalPBR(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    
    outSurfaceData.metallic = SampleMetallic(uv);
    half emissionMask;
    outSurfaceData.emission = SampleEmissionMask(uv, emissionMask);
    outSurfaceData.albedo = LerpPattern(uv, saturate(outSurfaceData.alpha * (1 - emissionMask)), outSurfaceData.albedo);
    outSurfaceData.specular = SampleSpecular();
#if defined(_PATTERNMAP)
    outSurfaceData.alpha = 1;
#endif
   AlphaDiscard(outSurfaceData.alpha);
}

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
#if defined(_PATTERNMAP)
    outSurfaceData.alpha = 1;
#endif
#if defined(_ENABLE_HAIR)
    outSurfaceData.translucency = SampleTranslucency(uv);
#endif
}



#endif //URP_INPUT_INCLUDED