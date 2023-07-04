// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_LIT_PASS_INCLUDED
#define URP_LIT_PASS_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting.hlsl"
#include "ShaderLibrary/Blend.hlsl"
#include "ShaderLibrary/Util.hlsl"

#define _SubsurfaceColor half3(0.08908623,0.02129363,0.01580406)
#if defined(_ENABLE_SKIN)
#define _TranslucencyPower 5
#define _ShadowStrength 0
#define _Distortion 1
#endif
inline void InitializeBRDFData_SkinMask(half3 albedo, half metallic, half3 specular, half smoothness, half alpha,
    out BRDFData outBRDFData) {
    half oneMinusReflectivity, reflectivity;
    if (alpha > 0) {
        reflectivity = ReflectivitySpecular(specular);
        oneMinusReflectivity = 1.0 - reflectivity;
        outBRDFData.diffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
        outBRDFData.specular = specular;
    }
    else {
        oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
        reflectivity = 1.0 - oneMinusReflectivity;
        outBRDFData.diffuse = albedo * oneMinusReflectivity;
        outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);
    }

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
}
half3 DirectBDRF_Skin(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS) {
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);
    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular; // + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

half3 LightingPhysicallyBasedSkin(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS, half NdotL, half skinMask) {
    half3 diffuseLighting = brdfData.diffuse * SAMPLE_TEXTURE2D(_LUTMap, sampler_LUTMap,
        float2((NdotL * 0.5 + 0.5), (NdotL * 0.5 + 0.5))).rgb;
    diffuseLighting = lerp(brdfData.diffuse * NdotL, diffuseLighting, skinMask);
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    radiance += lerp(0, 0.2, skinMask);
    return (DirectBDRF_Skin(brdfData, normalWS, lightDirectionWS, viewDirectionWS) + diffuseLighting) * radiance;
}

half3 LightingPhysicallyBasedSkin(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL,
    half skinMask) {
    return LightingPhysicallyBasedSkin(brdfData, light.color, light.direction,
        light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS,
        NdotL, skinMask);
}

half4 SkinFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half skinMask) {
    BRDFData brdfData;
    InitializeBRDFData_SkinMask(albedo, metallic, specular, smoothness, skinMask, brdfData);
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 GI = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS,
        inputData.viewDirectionWS);
    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half3 DirectBDRF = LightingPhysicallyBasedSkin(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS,
        NdotL, skinMask);
    // half3  DirectBDRF2= LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);
    //  Subsurface Scattering
    half3 sss = skinMask * SSS(NdotL, mainLight, inputData.normalWS, inputData.viewDirectionWS, metallic,
        _SubsurfaceColor);

    half3 color = GI + DirectBDRF * _lightPower + sss;

#ifdef _ADDITIONAL_LIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, inputData.positionWS);
        NdotL = saturate(dot(inputData.normalWS, light.direction));
        color += LightingPhysicallyBasedSkin(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL, skinMask);
        //  Subsurface Scattering
        color += skinMask * _lightPower * SSS(NdotL, light, inputData.normalWS, inputData.viewDirectionWS, metallic, _SubsurfaceColor);
    }
#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif
    return half4(color + emission, 1);
}
half4 HairFragment(
    InputData inputData,

    half3 tangentWS,
    half3 bitangentWS,

    half3 albedo,
    half3 specular,
    half occlusion,

    half specularShift,
    half3 specularTint,
    half smoothness,

    half rimTransmissionIntensity,
    half ambientReflection,
    half translucency
) {

    //  TODO: Simplify this...
    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness); // * saturate(noise.r * 2) );
    half roughness1 = PerceptualRoughnessToRoughness(perceptualRoughness);
    half pbRoughness1 = RoughnessToBlinnPhongSpecularExponent(roughness1);

    half3 strandDirWS;

    if (_StrandDir == 0) {
        strandDirWS = cross(inputData.normalWS, tangentWS);
    }
    else {
        strandDirWS = cross(inputData.normalWS, bitangentWS);
    }

    half3 t1 = ShiftTangent(strandDirWS, inputData.normalWS, specularShift);

    //  Start Lighting    
    //  (From HDRP) Note: For Kajiya hair we currently rely on a single cubemap sample instead of two, as in practice smoothness of both lobe aren't too far from each other.
    //  and we take smoothness of the secondary lobe as it is often more rough (it is the colored one).
    //  NOPE: We use primary!!!!! 
    half3 GI = GlobalIlluminationHair(albedo, specular, roughness1, perceptualRoughness, occlusion, inputData.bakedGI,
        inputData.normalWS, inputData.viewDirectionWS, bitangentWS, ambientReflection);

    //  Main Light
    Light light = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(light, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));
    half3 DirectLight = LightingHair(albedo, specular, light, inputData.normalWS, inputData.viewDirectionWS,
        pbRoughness1, t1, specularTint,
        rimTransmissionIntensity);

    half NdotL = 0;
    half3 sss = 0;
#if  defined(_SCATTERING)
    NdotL = saturate(dot(inputData.normalWS, light.direction));
    sss = SSS(NdotL, light, inputData.normalWS, inputData.viewDirectionWS, translucency, albedo) * 4;
#endif

    half3 color = GI + DirectLight + sss;
    //  Additional Lights
#ifdef _ADDITIONAL_LIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i) {

        light = GetAdditionalLight(i, inputData.positionWS);
        color += LightingHair(albedo, specular, light, inputData.normalWS, inputData.viewDirectionWS, pbRoughness1, t1, specularTint, rimTransmissionIntensity);
#if  defined(_SCATTERING)
        color += SSS(NdotL, light, inputData.normalWS, inputData.viewDirectionWS, translucency, albedo) * 4;
#endif
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEXf
    color += inputData.vertexLighting * albedo;
#endif

    return half4(color, 1); // alpha?
}







half4 LitFrag(Varyings input
#ifdef _VFACE
    , half facing : VFACE
#endif
) : SV_Target{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
#if defined(_ENABLE_LIT)
    InitializeSurfaceDataPBR(input.uv, surfaceData);
#endif

#if defined(_ENABLE_HAIR) || defined(_ENABLE_SKIN)
    InitializeSurfaceData(input.uv, surfaceData);
#endif
#if defined(_ENABLE_HAIR)
#if defined(_VFACE)
    surfaceData.normalTS.z *= facing;
#endif
#endif
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    half4 color=1;
#if defined(_ENABLE_HAIR)
     color = HairFragment( inputData,
#if defined(_NORMALMAP)
        input.tangentWS.xyz,
        input.bitangentWS.xyz,
#else
        half3(0.0h, 0.0h, 1.0h),
        half3(0.0h, 0.0h, 1.0h),
#endif
        surfaceData.albedo,
        surfaceData.specular,
        surfaceData.occlusion,

        _SpecularShift * surfaceData.metallic,
        _SpecularTint.rgb,
        _SpecularExponent * surfaceData.smoothness,

        _RimTransmissionIntensity,
        _AmbientReflection,

        surfaceData.translucency
    );
#ifdef _EMISSION
#ifdef _HairGradient
    //---maskÍ¼//
   // float2 uvGradientMaskTex = TRANSFORM_TEX(input.uv, _GradientMaskMap);
   //  float4 transiton = SAMPLE_TEXTURE2D(_GradientMaskMap, sampler_GradientMaskMap, uvGradientMaskTex).rrrr;
   //  float4 finalcol =mask>0.5? Gradient * mask: Gradient*(1-mask);
   // float4 finalcol1 = Gradient * transiton;
   //  finalcol1 *= fill;
   // color.rgb += finalcol1.rgb;
    //×Ô¼º¼ÆËãmask----------------------------------------
    float2 uvGradientTex = TRANSFORM_TEX(inputData.positionWS.xy, _GradientMap);
    float2 uvGradient = float2(_Gradient_U_Speed, _Gradient_V_Speed) * _Time.y + uvGradientTex;
    float4 Gradient = SAMPLE_TEXTURE2D(_GradientMap, sampler_GradientMap, uvGradient);
    float4 mask = lerp(float4(0, 0, 0, 0), float4(1, 1, 1, 1), (2 - inputData.positionWS.y / _Fill)) * _Intensity;
    mask = mask.a > 0 ? mask : 0;
    float4 finalcol = Gradient * mask;
    finalcol *= _GradientColor;
    float4 fill = step((2 - inputData.positionWS.y / _Fill), 1);
    finalcol *= fill;
    color.rgb += finalcol.rgb;

#endif 
#endif 
    color.a = surfaceData.alpha;
    color.rgb += surfaceData.emission;
#endif 
#if defined(_ENABLE_SKIN)
     color = SkinFragmentPBR(
        inputData,
        surfaceData.albedo,
        surfaceData.metallic,
        surfaceData.specular,
        surfaceData.smoothness,
        surfaceData.occlusion,
        surfaceData.emission,
        //  Subsurface Scattering
        surfaceData.alpha
    );
#endif
#if defined(_ENABLE_LIT)
     color = URPFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha); 
#endif
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif //URP_LIT_PASS_INCLUDED