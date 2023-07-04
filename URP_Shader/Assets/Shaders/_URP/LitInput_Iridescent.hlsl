#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1 

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half4 _SpecColor;
half _EnvExposure,_SHExposure,_envBDRFFactor,_PunctualLightSpecularExposure;
half4 _EmissionColor;
half4 _PanOrPulsate;

half _IridescenceThickness;
half _IridescneceEta2;
half _IridescneceEta3;
half _IridescneceKappa3;
half4 _IridescenceThicknessRemap;


CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);

TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);

TEXTURE2D(_IridescenceThicknessMap);    SAMPLER(sampler_IridescenceThicknessMap);

TEXTURE2D(_MaskMap);                    SAMPLER(sampler_MaskMap);

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
    half iridescenceThickness;
    half iridescenceEta2;
    half iridescenceEta3;
    half iridescenceKappa3;
};

half SampleIridescenceThickness(float2 uv)
{
    half iridescenceThickness;
#if _IRIDESCENCE_THICKNESSMAP
    iridescenceThickness = SAMPLE_TEXTURE2D(_IridescenceThicknessMap, sampler_IridescenceThicknessMap, uv).r;
    iridescenceThickness = _IridescenceThicknessRemap.x + iridescenceThickness * (_IridescenceThicknessRemap.y - _IridescenceThicknessRemap.x);
#else
    iridescenceThickness = _IridescenceThickness;
#endif
    return iridescenceThickness;
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

    outSurfaceData.iridescenceThickness = SampleIridescenceThickness(uv) > 0 ? SampleIridescenceThickness(uv) : _IridescenceThickness;
    outSurfaceData.iridescenceEta2 = _IridescneceEta2;
    outSurfaceData.iridescenceEta3 = _IridescneceEta3;
    outSurfaceData.iridescenceKappa3 = _IridescneceKappa3;
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

    outSurfaceData.iridescenceThickness = SampleIridescenceThickness(uv) > 0 ? SampleIridescenceThickness(uv) : _IridescenceThickness;
    outSurfaceData.iridescenceEta2 = _IridescneceEta2;
    outSurfaceData.iridescenceEta3 = _IridescneceEta3;
    outSurfaceData.iridescenceKappa3 = _IridescneceKappa3;
#if defined(_PATTERNMAP)
    outSurfaceData.alpha = 1;
#endif
}

#endif //URP_INPUT_INCLUDED