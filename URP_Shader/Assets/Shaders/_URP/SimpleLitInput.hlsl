#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START (UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half4 _SpecColor;
half _BaseMapAlphaAsSmoothness;
CBUFFER_END

TEXTURE2D(_BaseMap);
SAMPLER (sampler_BaseMap);

#if defined(_NORMALMAP)
TEXTURE2D (_NSMap); SAMPLER (sampler_NSMap);
#endif

TEXTURE2D (_EmissionMap);
SAMPLER (sampler_EmissionMap);

#if defined(_PATTERNMAP)
TEXTURE2D(_PatternMap);       SAMPLER(sampler_PatternMap);
#endif

#if defined(_MATCAP)
TEXTURE2D(_MatcapMap);       SAMPLER(sampler_MatcapMap);
#endif


#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"

struct SurfaceData {
    half3 albedo;
    half occlusion;
    half3 normalTS;
    half smoothness;
    half metallic;
    half3 emission;
    half3 specular;
    half alpha;
};


inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData) {

    if (_BaseMapAlphaAsSmoothness > 0) {
        SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.smoothness, outSurfaceData.alpha);
        outSurfaceData.smoothness *= _SpecColor.a;
        outSurfaceData.occlusion = 1;
        outSurfaceData.normalTS = half3(0.0h, 0.0h, 1.0h);
    } else {
        SampleBaseMap(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
        SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    }
    AlphaDiscard(outSurfaceData.alpha);

    outSurfaceData.metallic = 0;
    half emissionMask = 1;
    outSurfaceData.emission = SampleEmissionMask(uv, emissionMask);
    outSurfaceData.albedo = LerpPattern(uv, saturate(outSurfaceData.alpha * (1 - emissionMask)), outSurfaceData.albedo);
    outSurfaceData.specular = SampleSpecular();
}

#endif //URP_INPUT_INCLUDED
