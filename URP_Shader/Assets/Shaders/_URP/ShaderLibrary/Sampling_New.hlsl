#ifndef URP_SAMPLING_NEW_INCLUDED
#define URP_SAMPLING_NEW_INCLUDED

#include "BaseSampling.hlsl"
#include "ChangeColor.hlsl"
#include "VFX.hlsl"

void SampleBaseMapOnly(float2 uv, out half3 albedo, out half occlusion, out half alpha){
    SampleRGBA(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), albedo, occlusion);
    alpha = 1;
    
    #if defined(_ALPHATEST_ON) | defined(_MASKMAP)
    alpha = occlusion;
    occlusion = 1;
    #endif
    
    albedo = change_color(albedo, alpha);
    
    #ifdef _ALPHAPREMULTIPLY_ON
    albedo *= alpha;
    #endif
}

void SampleBaseMap(float2 uv, out half3 albedo, out half smoothness, out half alpha){
     SampleRGBA(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), albedo, smoothness);
     alpha = 1;
     #if defined(_ALPHATEST_ON) | defined(_MASKMAP) | defined (_PATTERNMAP)
     alpha = smoothness;
    
     
     #if !defined(_ENV)
     SampleR(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), smoothness);
     #endif
     #endif
     
     albedo = change_color(albedo, alpha);
     
     #ifdef _ALPHAPREMULTIPLY_ON
     albedo *= alpha;
     #endif
 }
 

half3 LerpPattern(float2 uv, float mask, half3 albedo){
    #if defined(_PATTERNMAP)
    half3 pattern;
    half patternAlpha;
    // mask = remap(mask, _ValueRemap);
    // CheapContrast_float(mask, _Contrast, mask);
    SampleRGBA(uv, TEXTURE2D_ARGS(_PatternMap, sampler_BaseMap), pattern, patternAlpha);
    albedo = lerp(albedo, pattern, mask * patternAlpha);
    #endif

    return albedo;
}

half3 SampleSpecular(){
    half3 specular = half3(0.0h, 0.0h, 0.0h);
    #if defined (_SPECULAR_COLOR) | defined(_SPECULAR_SETUP)
        specular = _SpecColor.rgb;
    #endif
    
    return specular;
}

void SampleNormalPBR(float2 uv, out half3 normalTS, out half smoothness)
{
#if defined(_NORMALMAP)
    half4 n = SAMPLE_TEXTURE2D(_NSMap, sampler_NSMap, uv);
    normalTS = n.rgb * 2.0h - 1.0h;
    smoothness = n.a;
#else
    normalTS = half3(0.0h, 0.0h, 1.0h);
    smoothness = 1;
#endif
}

void SampleNormal(float2 uv, out half3 normalTS, out half occlusion)
{
 
#if defined(_NORMALMAP)
    half4 n = SAMPLE_TEXTURE2D(_NSMap, sampler_NSMap, uv);
    normalTS = n.rgb * 2.0h - 1.0h;
    occlusion = n.a ;
#else
    normalTS = half3(0.0h, 0.0h, 1.0h);
    occlusion = 1;
#endif
}

#if !defined(_ENV)
half SampleMetallic(float2 uv){
    half metallic = 0.0h;
    SampleG(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), metallic);
    return metallic;
}
#endif

half3 SampleEmission(float2 uv){
    half3 emission = 0;
    half emissionMask = 1;
    #ifdef _EMISSION
    emission = emissive(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), emissionMask);
    #endif
    return emission;
}

half3 SampleEmissionMask(float2 uv, out float emissionMask){
    half3 emission = 0;
    emissionMask = 0;
    #ifdef _EMISSION
    emission = emissive(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), /*out*/ emissionMask);
    #endif
    return emission;
}
#endif //URP_SAMPLING_INCLUDED