#ifndef URP_HAIR_LIT_PASS_NEW_INCLUDED
#define URP_HAIR_LIT_PASS_NEW_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting_New.hlsl"

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
    } else {
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
    sss = SSS (NdotL, light, inputData.normalWS, inputData.viewDirectionWS, translucency, albedo) * 4;
#endif

    half3 color = GI + DirectLight + sss;
    //  Additional Lights
#ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i) {

            light = GetAdditionalLight(i, inputData.positionWS);
            color += LightingHair(albedo, specular, light, inputData.normalWS, inputData.viewDirectionWS, pbRoughness1,  t1,  specularTint,  rimTransmissionIntensity);
#if  defined(_SCATTERING)
            color += SSS(NdotL, light, inputData.normalWS, inputData.viewDirectionWS , translucency, albedo) * 4;
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
) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

#if defined(_VFACE)
        surfaceData.normalTS.z *= facing;
#endif
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = HairFragment(
        inputData,
#if defined(_NORMALMAP)
        input.tangentWS.xyz, 
        input.bitangentWS.xyz,
#else
        half3(0.0h, 0.0h, 1.0h),
        half3(1.0h, 0.0h, 0.0h),
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
    
    color.a = surfaceData.alpha;
    color.rgb += surfaceData.emission;
    
    //  Add fog
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}
half4 LitFrag1(Varyings input
#ifdef _VFACE
  , half facing : VFACE
#endif
) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;
//    float2 pos = input.screenPos.xy / input.screenPos.w;
    InitializeSurfaceData(input.uv, surfaceData);

#if defined(_VFACE)
        surfaceData.normalTS.z *= facing;
#endif
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = HairFragment(
        inputData,
#if defined(_NORMALMAP)
        input.tangentWS.xyz, 
        input.bitangentWS.xyz,
#else
        half3(0.0h, 0.0h, 1.0h),
        half3(1.0h, 0.0h, 0.0h),
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
    
    color.a = surfaceData.alpha;
    color.rgb += surfaceData.emission;
    
    //  Add fog
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

half4 LitFrag2(Varyings input
#ifdef _VFACE
  , half facing : VFACE
#endif
) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;

   InitializeSurfaceData2(input.uv, surfaceData);

#if defined(_VFACE)
        surfaceData.normalTS.z *= facing;
#endif
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = HairFragment(
        inputData,
#if defined(_NORMALMAP)
        input.tangentWS.xyz, 
        input.bitangentWS.xyz,
#else
        half3(0.0h, 0.0h, 1.0h),
        half3(1.0h, 0.0h, 0.0h),
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
    
    color.a = surfaceData.alpha;
    color.rgb += surfaceData.emission;
    
    //  Add fog
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}
#endif // URP_HAIR_LIT_PASS_INCLUDED
