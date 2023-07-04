#ifndef URP_TREE_INPUT_INCLUDED
#define URP_TREE_INPUT_INCLUDED

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
CBUFFER_END

TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

#endif //URP_TREE_INPUT_INCLUDED