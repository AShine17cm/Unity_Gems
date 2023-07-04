#ifndef URP_VFX_PARTICLES_INPUT_INCLUDED
#define URP_VFX_PARTICLES_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
#if defined(_SOFTPARTICLES_ON)
TEXTURE2D(_CameraDepthTexture);            SAMPLER(sampler_CameraDepthTexture);
#endif

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half _InvFade;
CBUFFER_END

#endif //URP_VFX_PARTICLES_INPUT_INCLUDED