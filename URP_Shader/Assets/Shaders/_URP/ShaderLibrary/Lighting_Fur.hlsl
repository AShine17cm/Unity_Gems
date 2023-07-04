#ifndef URP_LIGHTING_FUR_INCLUDED
#define URP_LIGHTING_FUR_INCLUDED

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
//---------------
half FabricScatterFresnelLerp(half nv, half scale)
{
    half t0 = Pow4 (1 - nv); 
    half t1 = 0.4 * (1 - nv);
    return (t1 - t0) * scale + t0;
}
half3 Fabric_EnvironmentBRDF(BRDFData brdfData, half3 indirectDiffuse,half3 viewDirectionWS,half3 normalWS,half3 lightDirectionWS)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    float NoV = saturate(dot(normalWS, viewDirectionWS));
    float NoL = saturate(dot(normalWS, lightDirectionWS));
    c +=_FabricScatterColor * (NoL *0.5 + 0.5) * FabricScatterFresnelLerp(NoV, _FabricScatterScale);
    return c;
}
//采用Inverted Gaussian模型做为布料的高光分布模型
float FabricD (float NdotH,float roughness)
{
    return 0.96 * pow(1 - NdotH, 2) + 0.057; 
}
//---------------
half3 FABRIC_DirectBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d1 = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    d1= brdfData.roughness2 / (d1 * d1);
    float d=brdfData.roughness > 0.99 ? FabricD (NoH,brdfData.roughness) : d1;

    half LoH2 = LoH * LoH;
    half specularTerm = d /( max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}
//---------------
half3 GlobalIllumination_Fabric(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS,half3 lightDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

    return Fabric_EnvironmentBRDF(brdfData, indirectDiffuse, viewDirectionWS, normalWS, lightDirectionWS);
}
//---------------
half3 LightingPhysicallyBased_Fabric(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return FABRIC_DirectBDRF(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}
half3 LightingPhysicallyBased_Fabric(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingPhysicallyBased_Fabric(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}
//---------------
half4 UniversalFragmentPBR_Fabric(InputData inputData, half3 albedo, half metallic, 
    half smoothness, half occlusion, half3 emission, half alpha)
{
    BRDFData brdfData;
    InitializeBRDFData_URP(albedo, metallic, smoothness, alpha, brdfData);
    
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination_Fabric(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,mainLight.direction );
    color += LightingPhysicallyBased_Fabric(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color += LightingPhysicallyBased_Fabric(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif
    color += emission;

    return half4(color, alpha);
}
//---------------
half3 LightingLambert_Fabric(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
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
    float NoV = saturate(dot(normalWS, viewDirectionWS));
    float NoL = saturate(dot(normalWS, mainLight.direction));
    diffuseColor +=_FabricScatterColor * (NoL *0.5 + 0.5) * FabricScatterFresnelLerp(NoV, _FabricScatterScale);
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
 //   finalColor += specularColor;
    
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
