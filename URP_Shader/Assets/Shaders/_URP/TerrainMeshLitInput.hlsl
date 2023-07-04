#ifndef URP_TERRAIN_LIT_INCLUDED
#define URP_TERRAIN_LIT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _Control_ST;
half _Splat0_Smoothness, _Splat1_Smoothness;
half _Splat0_S, _Splat1_S; 

#ifdef TM_3_TEX
half _Splat2_Smoothness;
half _Splat2_S;
#endif

#ifdef TM_4_TEX
half _Splat3_Smoothness;
half _Splat3_S;
#endif
CBUFFER_END

TEXTURE2D(_Control);    SAMPLER(sampler_Control);
TEXTURE2D(_Splat0);     SAMPLER(sampler_Splat0);
TEXTURE2D(_Splat1);

#if defined( _NORMALMAP) 
TEXTURE2D(_Splat0_Normal);     SAMPLER(sampler_Splat0_Normal);
TEXTURE2D(_Splat1_Normal);
#endif

#ifdef TM_3_TEX
TEXTURE2D(_Splat2);
    #if defined(_NORMALMAP) 
    TEXTURE2D(_Splat2_Normal);
    #endif
#endif

#ifdef TM_4_TEX
TEXTURE2D(_Splat3);
    #if defined(_NORMALMAP)
    TEXTURE2D(_Splat3_Normal);
    #endif
#endif

struct SurfaceData
{
    half3 albedo;
    half  smoothness;
    half  metallic;
    half3 specular;
    half3 emission;
    half  alpha;
};

#include "ShaderLibrary/BaseSampling.hlsl"
inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    SampleRGBA(uv, TEXTURE2D_ARGS(_Control, sampler_Control), outSurfaceData.albedo, outSurfaceData.alpha );
    outSurfaceData.smoothness = 0;
    outSurfaceData.metallic = 0.0h;
    outSurfaceData.emission = 0.0h;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceData.alpha = 1;
}
#endif //URP_TERRAIN_LIT_INCLUDED