#ifndef URP_INPUT_NEW_INCLUDED
#define URP_INPUT_NEW_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#define _CUTOFF_OR_TRANSUV 1

CBUFFER_START (UnityPerMaterial)
float4 _BaseMap_ST;
half _Cutoff;

half4 _SpecColor;

half4 _EmissionColor;
half4 _PanOrPulsate;

half _SpecularShift;
half4 _SpecularTint;
half _SpecularExponent;


half _RimTransmissionIntensity;
half _AmbientReflection;

half _TranslucencyPower;
half _ShadowStrength;
half _Distortion;

half _StrandDir;

CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER (sampler_BaseMap);

TEXTURE2D (_NSMap); SAMPLER (sampler_NSMap);

TEXTURE2D(_EmissionMap);       SAMPLER(sampler_EmissionMap);


#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"

struct SurfaceData {
    half3 albedo;
    half occlusion;
    half3 normalTS;
    half smoothness;
    half metallic;
    half3 specular;
    half alpha;
    half3 emission;

    half translucency;
};

half SampleTranslucency(float2 uv) {
    half translucency = .5;
#if defined(_ALPHATEST_ON) && defined(_EMISSION) 
    SampleB(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), translucency);
    //translucency = 1;
#endif
    return translucency;
}
float mix(float2 x,float2 y,float z)
{
    return x * (1 - z) + y * z ;
}
//frac( cos( ( dot(p,K) ) * K2 )            , K = < e^pi, 2^sqrt(2) >, K2 = 12345.6789 
float Noise(float2 uv)
	{
		float2 seed = 32.0 * uv;
	    float noise = frac( cos( dot(seed, float2( 23.14069263277926, 2.665144142690225 ) ) ) * 12345.6789 );
		noise = frac(noise );
        return noise;
	}
float isDithered(float2 pos, float alpha)
{ 
    pos *= _ScreenParams.xy;

    // Define a dither threshold matrix which can
    // be used to define how a 4x4 set of pixels
    // will be dithered
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    int index = (int(pos.x) % 4) * 4 + int(pos.y) % 4;
    return alpha - DITHER_THRESHOLDS[index];
}


inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData) {
    SampleBaseMap_Hair(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
     AlphaDiscard(outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);

    outSurfaceData.specular = SampleSpecular();
    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}
inline void InitializeSurfaceData1(float2 uv, out SurfaceData outSurfaceData,float2 pos) {

    SampleBaseMap_Hair(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
  //  outSurfaceData.alpha=(outSurfaceData.alpha-_Cutoff)/max(fwidth(outSurfaceData.alpha),0.0001)+0.5;
   // clip(isDithered(pos,outSurfaceData.alpha)-_Cutoff);
    clip(outSurfaceData.alpha-_Cutoff*Noise(uv));
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    outSurfaceData.specular = SampleSpecular();
    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}
inline void InitializeSurfaceData2(float2 uv, out SurfaceData outSurfaceData) {
    SampleBaseMap_Hair(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);
    outSurfaceData.specular = SampleSpecular();
    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}
#endif //URP_INPUT_INCLUDED
