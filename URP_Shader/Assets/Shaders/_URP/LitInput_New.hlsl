#ifndef URP_INPUT_NEW_INCLUDED
#define URP_INPUT_NEW_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1 

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half4 _SpecColor;
half _EnvExposure,_SHExposure,_envBDRFFactor,_PunctualLightSpecularExposure;
half4 _EmissionColor;
half4 _EnvironmentColor;
half4 _PanOrPulsate;


CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);

TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);

TEXTURECUBE(_EnvironmentMap);	       SAMPLER(sampler_EnvironmentMap);

#if defined(_PATTERNMAP)
TEXTURE2D(_PatternMap);       SAMPLER(sampler_PatternMap);
#endif

#define _CUTOFF_OR_TRANSUV 1

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
    half  Mask;
};


inline void InitializeSurfaceDataPBR(float2 uv, out SurfaceData outSurfaceData)
{
    SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    SampleNormalPBR(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    outSurfaceData.metallic = SampleMetallic(uv);
    half emissionMask;
    outSurfaceData.emission = SampleEmissionMask(uv, emissionMask);
    outSurfaceData.specular = SampleSpecular();
    SampleR(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), outSurfaceData.Mask);
    
   // outSurfaceData.alpha = 1;

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
    outSurfaceData.specular = SampleSpecular();
    //outSurfaceData.alpha = 1;
  
    SampleR(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), outSurfaceData.Mask);

}
#endif //URP_INPUT_INCLUDED