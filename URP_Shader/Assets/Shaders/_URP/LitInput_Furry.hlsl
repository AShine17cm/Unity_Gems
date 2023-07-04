#ifndef URP_INPUT_INCLUDED
#define URP_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"



CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _LayerTex_ST;

half _Cutoff;
half3 _RimColor;
half  _RimWidth;
half _RimIntensity;
half _RimSmoothness;
half4 _SpecColor;
half4 _ShadowColor;
half3 _FabricScatterColor;
half  _FabricScatterScale;
half3 _Gravity;
half _FurLength;
half _MaskSmooth;
half _NoiseScale;
half _CutoffEnd; 
half _EdgeFade;
half _GravityStrength;
half _ShadowAO;
half3 _UVOffset;
CBUFFER_END
half FUR_OFFSET;


TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

TEXTURE2D(_NSMap);            SAMPLER(sampler_NSMap);

TEXTURE2D(_LayerTex);         SAMPLER(sampler_LayerTex);



#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/BaseSampling.hlsl"
#include "ShaderLibrary/ChangeColor.hlsl"

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
void SampleBaseMapOnly(float2 uv, out half3 albedo, out half occlusion, out half alpha){
    SampleRGBA(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), albedo, occlusion);
    alpha = 1;
    
    #if defined(_ALPHATEST_ON) | defined(_MASKMAP)
    alpha = occlusion;
    occlusion = 1;
    #endif
    
  //  albedo = change_color(albedo, alpha);
    
    #ifdef _ALPHAPREMULTIPLY_ON
    albedo *= alpha;
    #endif
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

half3 SampleSpecular(){
    half3 specular = half3(0.0h, 0.0h, 0.0h);
    #if defined (_SPECULAR_COLOR) | defined(_SPECULAR_SETUP)
        specular = _SpecColor.rgb;
    #endif
    
    return specular;
}
void SampleNormal(float2 uv, out half3 normalTS, out half smoothness)
{
    half specSmoothness = 1;
#if defined(_SPECULAR_COLOR) | defined(_SPECULAR_SETUP)
    specSmoothness = _SpecColor.a;
#endif

#if defined(_NORMALMAP)
    half4 n = SAMPLE_TEXTURE2D(_NSMap, sampler_NSMap, uv);
    normalTS = n.rgb * 2.0h - 1.0h;
    smoothness = n.a * specSmoothness;
#else
    normalTS = half3(0.0h, 0.0h, 1.0h);
    smoothness = specSmoothness;
#endif
}
inline void InitializeSurfaceDataPBR(float2 uv, out SurfaceData outSurfaceData)
{
    half2 UVbasemap = uv.xy * _BaseMap_ST.xy * _NoiseScale + _BaseMap_ST.zw;//保持和layerTex同样缩放
    SampleBaseMapOnly(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    SampleNormalPBR(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    
   
    outSurfaceData.metallic = 0;

    outSurfaceData.emission = 0;
    
    SampleRGB(UVbasemap, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), outSurfaceData.albedo);
   
    outSurfaceData.specular = SampleSpecular();
    outSurfaceData.alpha = 1;
     //AlphaDiscard(outSurfaceData.alpha); 
}

inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    SampleBaseMapOnly(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
     outSurfaceData.alpha = 1;
    //AlphaDiscard(outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    
    outSurfaceData.metallic = 0 ;

    outSurfaceData.emission =0;
    SampleRGB(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), outSurfaceData.albedo);
    outSurfaceData.specular = SampleSpecular();

}
#endif //URP_INPUT_INCLUDED