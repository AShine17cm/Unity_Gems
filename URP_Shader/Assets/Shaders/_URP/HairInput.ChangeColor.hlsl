#ifndef URP_HAIR_INPUT_INCLUDED
#define URP_HAIR_INPUT_INCLUDED

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

half4 _ChangeColor;
CBUFFER_END

TEXTURE2D(_BaseMap);
SAMPLER (sampler_BaseMap);

#if defined(_NORMALMAP)
TEXTURE2D (_NSMap); SAMPLER (sampler_NSMap);
#endif

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
#if defined(_ALPHATEST_ON) | defined(_EMISSION)
    SampleB(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), translucency);
    //translucency = 1;
#endif
    return translucency;
}

void SampleBaseMap_HairColor(float2 uv, out half3 albedo, out half occlusion, out half alpha) {
    SampleRGBA(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), albedo, alpha);

#if !defined(_ENV)
    SampleR(uv, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), occlusion);
#endif


    albedo = change_HairColor(albedo, alpha);

#ifdef _ALPHAPREMULTIPLY_ON
    albedo *= alpha;
#endif
}

half3 LimitSpecualarValue(half3 color,half3 specular)
{
    half3 hsvcolor = rgb2hsv(color);
    half3 hsvSpecular = rgb2hsv(specular);
    hsvSpecular.x = hsvcolor.x;
    hsvSpecular.y = hsvcolor.y;

   // hsvSpecular.z = 0.05;
  // hsvSpecular.z = 0.3;
   // hsvSpecular.z = normalize(hsvSpecular.z);
    if (hsvSpecular.z <= 0.05)
        hsvSpecular.z = 0.05 + (hsvSpecular.z / 1) * 0.3;
    else if (hsvSpecular.z >= 0.05 && hsvSpecular.z <= 0.3)
        hsvSpecular.z = hsvSpecular.z;
    else if (hsvSpecular.z >= 0.3)
        hsvSpecular.z = 0.3;
   // hsvSpecular.z = (hsvSpecular.z >= 0.7 && hsvSpecular.z <= 0.8) ? hsvSpecular.z : pow (hsvSpecular.z ,2);

    half3 rgbSpecular = hsv2rgb(hsvSpecular);
    return rgbSpecular;
}
half3 SampleSpecularColor() {
    half3 specular = half3(0.0h, 0.0h, 0.0h);
#if defined (_SPECULAR_COLOR) | defined(_SPECULAR_SETUP)
    specular = _ChangeColor.rgb;
   // specular = (rgb2hsv(specular).z<=0.5)? LimitSpecualarValue1(specular)  :LimitSpecualarValue(specular) * _ChangeColor.rgb;
     specular = LimitSpecualarValue(_ChangeColor.rgb,specular);
#endif

    return specular;
}

inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData) {
    SampleBaseMap_HairColor(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    AlphaDiscard(outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);

    outSurfaceData.specular = SampleSpecularColor();
   // outSurfaceData.specular = SampleSpecular();

    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}
inline void InitializeSurfaceData2(float2 uv, out SurfaceData outSurfaceData) {
   
    SampleBaseMap_HairColor(uv, outSurfaceData.albedo, outSurfaceData.occlusion, outSurfaceData.alpha);
    SampleNormal(uv, outSurfaceData.normalTS, outSurfaceData.smoothness);

    outSurfaceData.specular = SampleSpecularColor();
    //outSurfaceData.specular = SampleSpecular();

    outSurfaceData.emission = SampleEmission(uv);
    outSurfaceData.metallic = SampleMetallic(uv);
    outSurfaceData.translucency = SampleTranslucency(uv);
}

#endif //URP_HAIR_INPUT_INCLUDED
