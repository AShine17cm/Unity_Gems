#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1 

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;

half4 _SpecColor;

half4 _EmissionColor;
half4 _PanOrPulsate;
half  _lightPower;
half4 _ChangeColor;
half3  _addSkinColor;

CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);
TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);

TEXTURE2D(_LUTMap);          SAMPLER(sampler_LUTMap);

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
}

#endif //URP_INPUT_INCLUDED