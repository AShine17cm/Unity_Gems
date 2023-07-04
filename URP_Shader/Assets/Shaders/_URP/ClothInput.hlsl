#ifndef URP_CLOTH_INPUT_INCLUDED
#define URP_CLOTH_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;
half4   _SpecColor;

half    _Anisotropy;
half3   _SheenColor;

half    _TranslucencyPower;
half    _TranslucencyStrength;
half    _ShadowStrength;
half    _ShadowOffset;
half    _Distortion;

half4 _EmissionColor;
half4 _PanOrPulsate;

CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);
TEXTURE2D(_EmissionMap);      SAMPLER(sampler_EmissionMap);

struct SurfaceData
{
    half3 albedo;
    half alpha;
    half3 normalTS;
    half translucency;
    half3 specular;
    half smoothness;
    half occlusion;
    half3 emission;
    half metallic;
};

#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"

inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    AlphaDiscard(outSurfaceData.alpha);
    SampleNormal(uv,  outSurfaceData.normalTS,  outSurfaceData.smoothness);
    outSurfaceData.specular = SampleSpecular();
    SampleG(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), outSurfaceData.translucency);
    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = 0;
}


#endif //URP_CLOTH_INPUT_INCLUDED