#ifndef URP_ROCK_INPUT_INCLUDED
#define URP_ROCK_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START (UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;
half4 _SpecColor;

half4 _TextureSize;
half _MossScale;
half _MossSmoothness;
half _HeightBlend;
half _BlendDistance;
half _BlendAngle;

half4 _ValueRemap;
half3 _VertexOffset;

half _EnableMoss;
half _EnableTriplanar;
half _EnableVertexOffset;
CBUFFER_END

TEXTURE2D(_BaseMap);
SAMPLER (sampler_BaseMap);
TEXTURE2D (_NSMap);
SAMPLER (sampler_NSMap);
TEXTURE2D (_MossMap);
SAMPLER (sampler_MossMap);


#include "ShaderLibrary/Sampling.hlsl"
#include "ShaderLibrary/Blend.hlsl"

struct SurfaceData {
    half3 albedo;
    half occlusion;
    half3 normalTS;
    half smoothness;
    half metallic;
    half3 emission;
    half3 specular;
    half alpha;
    half3 albedo_Moss;
};

inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData) {
    SampleBaseMap(uv, /*out*/outSurfaceData.albedo, /*out*/ outSurfaceData.occlusion, /*out*/ outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);

    AlphaDiscard(outSurfaceData.alpha);
    outSurfaceData.albedo_Moss = 0;
    if (_EnableMoss > 0) {
        SampleRGB(uv * _MossScale, TEXTURE2D_ARGS(_MossMap, sampler_MossMap), /*out*/ outSurfaceData.albedo_Moss);
    }
    
    outSurfaceData.metallic = 0;
    outSurfaceData.emission = 0;
    outSurfaceData.specular = SampleSpecular();
}

#ifdef _TRIPLANAR
#include "ShaderLibrary/Texturing.hlsl"
inline void InitializeSurfaceData_Triplanar(float2 uv, float3 positionWS, float3 normalWS, out SurfaceData outSurfaceData)
{
    half4 baseColor;
    TriplanarSample_float(_BaseMap, sampler_BaseMap, positionWS, normalWS, _TextureSize.rgb, _TextureSize.a, baseColor);
    outSurfaceData.albedo = baseColor.rgb;
    SampleA(uv, _BaseMap, sampler_BaseMap, outSurfaceData.occlusion);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    
    if(_EnableMoss>0){
        SampleRGB(uv * _MossScale, TEXTURE2D_ARGS(_MossMap, sampler_MossMap), /*out*/ outSurfaceData.albedo_Moss);
    }
    
    outSurfaceData.alpha = 1;
    outSurfaceData.metallic = 0;
    outSurfaceData.emission = 0;
    outSurfaceData.specular = SampleSpecular();
}
#endif
#endif //URP_ROCK_INPUT_INCLUDED
