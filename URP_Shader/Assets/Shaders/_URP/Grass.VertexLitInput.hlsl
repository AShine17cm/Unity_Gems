#ifndef URP_GRASS_INPUT_INCLUDED
#define URP_GRASS_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half3 _SubsurfaceColor;
half _TranslucencyPower;
half _ShadowStrength;
half _Distortion;
half _Range;
half _Speed;
half _CameraDistance;
CBUFFER_END

// #define _CameraDistance 100

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

#endif //URP_GRASS_INPUT_INCLUDED