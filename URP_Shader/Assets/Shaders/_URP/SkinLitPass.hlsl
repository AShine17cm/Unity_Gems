#ifndef URP_SKIN_LIT_PASS_INCLUDED
#define URP_SKIN_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Blend.hlsl"
#include "ShaderLibrary/Lighting.hlsl"


inline void InitializeBRDFData_SkinMask(half3 albedo, half metallic, half3 specular, half smoothness, half alpha,
                                        out BRDFData outBRDFData) {
    half oneMinusReflectivity, reflectivity;
    if (alpha > 0) {
        reflectivity = ReflectivitySpecular(specular);
        oneMinusReflectivity = 1.0 - reflectivity;
        outBRDFData.diffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
        outBRDFData.specular = specular;
    } else {
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

// From DirectBDRF
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
    return (DirectBDRF_Skin(brdfData, normalWS, lightDirectionWS, viewDirectionWS ) +diffuseLighting)* radiance;
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
            NdotL = saturate( dot(inputData.normalWS, light.direction) );
            color += LightingPhysicallyBasedSkin(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL, skinMask);
            //  Subsurface Scattering
            color += skinMask  * _lightPower *  SSS(NdotL, light, inputData.normalWS, inputData.viewDirectionWS, metallic, _SubsurfaceColor);
        }
#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
#endif
    return half4(color + emission, 1);
}

half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    //  Get the surface description
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

    //  Prepare surface data (like bring normal into world space and get missing inputs like gi
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, /*out*/ inputData);

    //  Apply lighting
    half4 color = SkinFragmentPBR(
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
    //  Add fog
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif //URP_SKIN_LIT_PASS_INCLUDED
