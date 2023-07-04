#ifndef URP_LIGHTING_INCLUDED
#define URP_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

inline void InitializeBRDFData_URP(half3 albedo, half metallic, half smoothness, half alpha,
                                   out BRDFData outBRDFData) {

    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;

#ifdef _ALPHAPREMULTIPLY_ON
    outBRDFData.diffuse *= alpha;
    alpha = alpha * oneMinusReflectivity + reflectivity;
#endif
}

float4 TransformWorldToShadowCoord_Test(float3 positionWS) {
    //#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    half cascadeIndex = ComputeCascadeIndex(positionWS);
    //#else
    //   half cascadeIndex = 0;
    //#endif

    return mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
}

half3 SampleSHVertex_Test(half3 normalWS) {
    return max(half3(0, 0, 0), SampleSH(normalWS));
}

// Sample baked lightmap. Non-Direction and Directional if available.
// Realtime GI is not supported.
half3 SampleLightmap(float2 lightmapUV) {
#ifdef UNITY_LIGHTMAP_FULL_HDR
    bool encodedLightmap = false;
#else
    bool encodedLightmap = true;
#endif

    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);

    // The shader library sample lightmap functions transform the lightmap uv coords to apply bias and scale.
    // However, universal pipeline already transformed those coords in vertex. We pass half4(1, 1, 0, 0) and
    // the compiler will optimize the transform away.
    half4 transformCoords = half4(1, 1, 0, 0);

#if defined(LIGHTMAP_ON)
    return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
#else
    return half3(0.0, 0.0, 0.0);
#endif
}

// From HDRP -----------------------------------------
float RoughnessToBlinnPhongSpecularExponent(float roughness) {
    return clamp(2 * rcp(roughness * roughness) - 2, FLT_EPS, rcp(FLT_EPS));
}


// From HDRP END -----------------------------------------

// Ref: Donald Revie - Implementing Fur Using Deferred Shading (GPU Pro 2)
// The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to the normal.
// The returned normal is NOT normalized.
half3 ComputeGrainNormal(half3 grainDir, half3 V) {
    half3 B = cross(-V, grainDir);
    return cross(B, grainDir);
}

// Fake anisotropic by distorting the normal.
// The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to N.
// Anisotropic ratio (0->no isotropic; 1->full anisotropy in tangent direction)
half3 GetAnisotropicModifiedNormal_URP(half3 grainDir, half3 N, half3 V, half anisotropy) {
    half3 grainNormal = ComputeGrainNormal(grainDir, V);
    return lerp(N, grainNormal, anisotropy);
}


half3 Lambert(half3 diffuse, half3 normalWS, half3 positionWS, half4 shadowCoord, half3 bakedGI, half3 emission) {
    Light mainLight = GetMainLight(shadowCoord);
    MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));
    half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
    half3 diffuseColor = bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);
    // diffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);;
#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, normalWS);
    }
#endif

    half3 finalColor = diffuseColor * diffuse + emission;
    
    return finalColor;
}

half3 Lambert(half3 diffuse, half3 normalWS, half4 shadowCoord, half3 bakedGI, half3 emission) {
    Light mainLight = GetMainLight(shadowCoord);
    MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));
    half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
    half3 diffuseColor = bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);
    // diffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);;

    half3 finalColor = diffuseColor * diffuse + emission;
    // finalColor =  mainLight.shadowAttenuation;
    return finalColor;
}

half3 Lambert(InputData inputData, half3 diffuse, half3 emission) {
    return Lambert(diffuse, inputData.normalWS, inputData.positionWS, inputData.shadowCoord, inputData.bakedGI,
                   emission);
}


half4 FragmentBlinnPhong(half3 positionWS, half3 normalWS, half3 viewDirectionWS,
                         half4 shadowCoord, half3 vertexLighting, half3 bakedGI,
                         half3 diffuse, half4 specularGloss, half smoothness, half3 emission, half alpha) {
    Light mainLight = GetMainLight(shadowCoord);
    MixRealtimeAndBakedGI(mainLight, normalWS,/*inout*/ bakedGI, half4(0, 0, 0, 0));
    half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
    half3 diffuseColor = bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);
    half3 specularColor = LightingSpecular(attenuatedLightColor, mainLight.direction, normalWS, viewDirectionWS,
                                           specularGloss, smoothness);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, normalWS);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, normalWS, viewDirectionWS, specularGloss, smoothness);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    diffuseColor += vertexLighting;
#endif

    half3 finalColor = diffuseColor * diffuse + emission;
    finalColor += specularColor;
    
    return half4(finalColor, alpha);
}

half4 FragmentBlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness, half3 emission,
                         half alpha) {
    return FragmentBlinnPhong(inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS,
                              inputData.shadowCoord, inputData.vertexLighting, inputData.bakedGI,
                              diffuse, specularGloss, smoothness, emission, alpha);
}


half4 URPFragmentPBR(InputData inputData, half3 albedo, half metallic,
                     half smoothness, half occlusion, half3 emission, half alpha) {
    BRDFData brdfData;
    InitializeBRDFData_URP(albedo, metallic, smoothness, alpha, brdfData);
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 GI = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS,
                                  inputData.viewDirectionWS);

    half3 DirectBDRF = LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);
    half3 color = DirectBDRF + GI;
#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif
    color += emission;
    return half4(color, alpha);
}


half3 GlobalIlluminationHair(
    half3 albedo,
    half3 specular,
    half roughness,
    half perceptualRoughness,
    half occlusion,

    half3 bakedGI,
    half3 normalWS,
    half3 viewDirectionWS,
    half3 bitangentWS,
    half ambientReflection
) {

    //  We do not handle backfaces properly yet. 
    half NdotV = dot(normalWS, viewDirectionWS);
    half s = sign(NdotV);
    //  Lets fix this for reflections?
    //NdotV = s * NdotV;

    //  Strengthen occlusion on backfaces    
    //occlusion = lerp(occlusion * 0.5, occlusion, saturate(1 + s));

    //  We do not "fix" the reflection vector. This gives us some scattering like reflections
    //half3 reflectNormalWS = GetAnisotropicModifiedNormal(s * bitangentWS, s * normalWS, viewDirectionWS, 0.6h);
    half3 reflectNormalWS = GetAnisotropicModifiedNormal_URP(bitangentWS, normalWS, viewDirectionWS, 0.6h);
    half3 reflectVector = reflect(-viewDirectionWS, reflectNormalWS);

    half fresnelTerm = Pow4(1.0 - saturate(NdotV));
    //  ??? perceptualRoughness *= saturate(1.2 - 0.8); //abs(bsdfData.anisotropy));
    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, perceptualRoughness, occlusion) *
        ambientReflection;

    //  EnvironmentBRDFHair
    half3 c = indirectDiffuse * albedo;
    float surfaceReduction = 1.0 / (roughness * roughness + 1.0);
    half reflectivity = ReflectivitySpecular(specular);
    half grazingTerm = saturate((1.0h - roughness) + reflectivity);
    c += surfaceReduction * indirectSpecular * lerp(specular, grazingTerm, fresnelTerm);
    return c;
}

half3 LightingHair(
    half3 albedo,
    half3 specular,
    Light light,
    half3 normalWS,
    half3 viewDirectionWS,

    half roughness1,
    half3 t1,
    half3 specularTint,
    half rimTransmissionIntensity
) {
    half NdotL = dot(normalWS, light.direction);
    half LdotV = dot(light.direction, viewDirectionWS);
    half NdotV = dot(normalWS, viewDirectionWS);
    float invLenLV = rsqrt(max(2.0 * LdotV + 2.0, FLT_EPS));

    half3 H = (light.direction + viewDirectionWS) * invLenLV;

    half3 hairSpec = specularTint * D_KajiyaKay(t1, H, roughness1);

    float3 halfDir = SafeNormalize(light.direction + viewDirectionWS);
    float NdotH = saturate(dot(normalWS, halfDir));
    half LdotH = saturate(dot(light.direction, halfDir));

    half3 F = F_Schlick(specular, LdotH);

    //  Reflection
    half3 specR = 0.25h * F * hairSpec * saturate(NdotL) * saturate(NdotV * FLT_MAX);

    //  Transmission // Yibing's and Morten's hybrid scatter model hack.
    half scatterFresnel1 = pow(saturate(-LdotV), 9.0h) * pow(saturate(1.0h - NdotV * NdotV), 12.0h);
    //  This looks shitty (using 20)   
    //half scatterFresnel2 = saturate(PositivePow((1.0h - NdotV), 20.0h));
    half scatterFresnel2 = saturate(Pow4(1.0h - NdotV));
    half transmission = scatterFresnel1 + rimTransmissionIntensity * scatterFresnel2;
    half3 specT = albedo * transmission;
    half3 diffuse = albedo * saturate(NdotL);

    //  combine
    half3 result = (diffuse + specR + specT) * light.color * light.distanceAttenuation * light.shadowAttenuation;
    return result;
}


half3 SSS(half NdotL, Light light, half3 normalWS, half3 viewDirectionWS, half translucency, half3 sssColor) {
#if  defined(_SCATTERING)
        half3 H = normalize(light.direction + normalWS * _Distortion);
        half transDot = dot(H, -viewDirectionWS );
        transDot = exp2(saturate(transDot) * _TranslucencyPower - _TranslucencyPower);
        // float I = pow(saturate(dot(H, -viewDirectionWS)), _TranslucencyPower)  * sssColor;
        half3 SSS = sssColor * transDot * (1.0 - saturate(NdotL)) * light.color * lerp(1.0h, light.shadowAttenuation, _ShadowStrength) * translucency;
        return SSS;
#else
    return half3(0, 0, 0);
#endif
}
//--------------------------------------------------

half3 SSS_New(half NdotL, Light light, half3 normalWS, half3 viewDirectionWS, half translucency, half3 sssColor) {
#if  defined(_SCATTERING)
        half3 H = normalize(light.direction + normalWS * _Distortion);
        half transDot = dot(H, -viewDirectionWS );
        transDot = exp2(saturate(transDot) * _TranslucencyPower - _TranslucencyPower);
        // float I = pow(saturate(dot(H, -viewDirectionWS)), _TranslucencyPower)  * sssColor;
        half3 SSS = sssColor * transDot * (1.0 - saturate(NdotL)) * light.color * lerp(1.0h, light.shadowAttenuation, _ShadowStrength) * translucency;
        return SSS;
#else
    return half3(0, 0, 0);
#endif
}

half3 TreeSSS(half3 normalWS, half3 viewDirectionWS, half3 lightDir, half3 sssColor) {
#if defined(_SCATTERING)
        half3 H = normalize(lightDir + normalWS * _Distortion);
        half transDot = dot(-H, viewDirectionWS );
        half transPow = pow(saturate(transDot), _TranslucencyPower);
        half3 s = sssColor * saturate(dot(transPow, _ShadowStrength));
        return saturate(s);
#else
    return half3(0, 0, 0);
#endif
}

half4 VertexLitLighting(half4 lambertAndFogFactor, half3 abledo, half3 emission, half occlusion, half alpha,
                        half2 lightmapUV = 0,
                        half3 matcap = 1) {
    half3 color = lambertAndFogFactor.rgb;
#ifdef LIGHTMAP_ON
    color += SampleLightmap(lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw);
#endif

#if defined(_MATCAP)
    color *= matcap;
#endif
    color *= abledo;
    color += emission;

#if defined(_BASEMAPSMOOTHNESS)
    if(_BaseMapAlphaAsSmoothness == 0){
        color *= occlusion;
    }
#endif

    color = MixFog(color, lambertAndFogFactor.a);
    return half4(color, alpha);
}

#endif //URP_LIGHTING_INCLUDED
