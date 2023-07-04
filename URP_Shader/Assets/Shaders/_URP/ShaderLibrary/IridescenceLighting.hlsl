#ifndef URP_LIGHTING_INCLUDED
#define URP_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"

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
// XYZ to CIE 1931 RGB color space(using neutral E illuminant)
static const half3x3 XYZ_TO_RGB = half3x3(2.3706743, -0.5138850, 0.0052982, -0.9000405, 1.4253036, -0.0146949, -0.4706338, 0.0885814, 1.0093968);
// Depolarization functions for natural light
inline float depol(float2 polV) { return 0.5 * (polV.x + polV.y); }
inline float3 depolColor(float3 colS, float3 colP) { return 0.5 * (colS + colP); }
// Fresnel equations for dielectric/dielectric interfaces.
void fresnelDielectric(in float ct1, in float n1, in float n2,
    out float2 R, out float2 phi) {

    float st1 = (1 - ct1 * ct1); // Sinus theta1 'squared'
    float nr = n1 / n2;

    if (Sq(nr) * st1 > 1) { // Total reflection

        float2 R = float2(1, 1);
        phi = 2.0 * atan(float2(-Sq(nr) * sqrt(st1 - 1.0 / Sq(nr)) / ct1,
            -sqrt(st1 - 1.0 / Sq(nr)) / ct1));
    }
    else {   // Transmission & Reflection

        float ct2 = sqrt(1 - Sq(nr) * st1);
        float2 r = float2((n2 * ct1 - n1 * ct2) / (n2 * ct1 + n1 * ct2),
            (n1 * ct1 - n2 * ct2) / (n1 * ct1 + n2 * ct2));
        phi.x = (r.x < 0.0) ? PI : 0.0;
        phi.y = (r.y < 0.0) ? PI : 0.0;
        R = Sq(r);
    }
}

// Fresnel equations for dielectric/conductor interfaces.
void fresnelConductor(in float ct1, in float n1, in float n2, in float k,
    out float2 R, out float2 phi) {

    if (k == 0) { // use dielectric formula to avoid numerical issues
        fresnelDielectric(ct1, n1, n2, R, phi);
        return;
    }

    float A = Sq(n2) * (1 - Sq(k)) - Sq(n1) * (1 - Sq(ct1));
    float B = sqrt(Sq(A) + Sq(2 * Sq(n2) * k));
    float U = sqrt((A + B) / 2.0);
    float V = sqrt((B - A) / 2.0);

    R.y = (Sq(n1 * ct1 - U) + Sq(V)) / (Sq(n1 * ct1 + U) + Sq(V));
    phi.y = atan2(2 * n1 * V * ct1, Sq(U) + Sq(V) - Sq(n1 * ct1)) + PI;

    R.x = (Sq(Sq(n2) * (1 - Sq(k)) * ct1 - n1 * U) + Sq(2 * Sq(n2) * k * ct1 - n1 * V))
        / (Sq(Sq(n2) * (1 - Sq(k)) * ct1 + n1 * U) + Sq(2 * Sq(n2) * k * ct1 + n1 * V));
    phi.x = atan2(2 * n1 * Sq(n2) * ct1 * (2 * k * U - (1 - Sq(k)) * V), Sq(Sq(n2) * (1 + Sq(k)) * ct1) - Sq(n1) * (Sq(U) + Sq(V)));
}
half3 ThinFilmIridescence(real iridescenceEta2, real iridescenceEta3, real iridescenceKappa3, real iridescenceThickness, float cosTheta1)
{
    float eta_1 = 1.0; // Air on top, no coat.
    float eta_2 = iridescenceEta2;
    float eta_3 = iridescenceEta3;
    float kappa_3 = iridescenceKappa3;

    // iridescenceThickness unit is micrometer for this equation here. Mean 0.5 is 500nm.
    float Dinc = 2 * eta_2 * iridescenceThickness;

    // Force eta_2 -> eta_1 when Dinc -> 0.0
    eta_2 = lerp(eta_1, eta_2, smoothstep(0.0, 0.03, Dinc));

    float cosTheta2 = sqrt(1.0 - Sq(eta_1 / eta_2) * (1 - Sq(cosTheta1)));

    // First interface
    float2 R12, phi12;
    fresnelDielectric(cosTheta1, eta_1, eta_2, R12, phi12);
    float2 R21 = R12;
    float2 T121 = float2(1.0, 1.0) - R12;
    float2 phi21 = float2(PI, PI) - phi12;

    // Second interface
    float2 R23, phi23;
    fresnelConductor(cosTheta2, eta_2, eta_3, kappa_3, R23, phi23);

    // Phase shift
    float OPD = Dinc * cosTheta2;
    float2 phi2 = phi21 + phi23;

    // Compound terms
    float3 I = float3(0, 0, 0);
    float2 R123 = clamp(R12 * R23, 1e-5, 0.9999);
    float2 r123 = sqrt(R123);
    float2 Rs = Sq(T121) * R23 / (float2(1.0, 1.0) - R123);

    // Reflectance term for m=0 (DC term amplitude)
    float2 C0 = R12 + Rs;
    float3 S0 = EvalSensitivity(0.0, 0.0);
    I += depol(C0) * S0;

    // Reflectance term for m>0 (pairs of diracs)
    float2 Cm = Rs - T121;

    [unroll(3)]
    for (int m = 1; m <= 3; ++m)
    {
        Cm *= r123;
        float3 SmS = 2.0 * EvalSensitivity(m * OPD, m * phi2.x);
        float3 SmP = 2.0 * EvalSensitivity(m * OPD, m * phi2.y);
        I += depolColor(Cm.x * SmS, Cm.y * SmP);
    }

    // Convert back to RGB reflectance
    I = max(mul(I, XYZ_TO_RGB), float3(0.0, 0.0, 0.0));

    return I;
}

half3 DirectBRDFIridescence(BRDFData brdfData, half iridescenceThickness, half iridescenceEta2, half iridescenceEta3, half iridescenceKappa3, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // Compute dot products
    float NdotL = dot(normalWS, lightDirectionWS);
    float NdotV = dot(normalWS, viewDirectionWS);


    float cosTheta1 = dot(halfDir, float3(lightDirectionWS));

    half3 I = ThinFilmIridescence(iridescenceEta2, iridescenceEta3, iridescenceKappa3, iridescenceThickness, cosTheta1);
    // Microfacet BRDF formula
    float D = D_GGX(NoH, brdfData.perceptualRoughness);
    float G = V_SmithJointGGX(NdotL, NdotV, brdfData.perceptualRoughness);


    half3 specularTerm1 = D * G * I / (4 * NdotL * NdotV);

#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    color += specularTerm1 * brdfData.specular + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif

}
half3 LightingPhysicallyBasedIridescence(BRDFData brdfData, half iridescenceThickness, half iridescenceEta2, half iridescenceEta3, half iridescenceKappa3, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBRDFIridescence(brdfData, iridescenceThickness, iridescenceEta2, iridescenceEta3, iridescenceKappa3, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}
half3 LightingPhysicallyBasedIridescence(BRDFData brdfData, half iridescenceThickness, half iridescenceEta2, half iridescenceEta3, half iridescenceKappa3, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingPhysicallyBasedIridescence(brdfData,  iridescenceThickness, iridescenceEta2, iridescenceEta3, iridescenceKappa3, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}

half3 EnvironmentBRDFIridescence(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half3 fresnelIridescent)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(brdfData.specular * fresnelIridescent, brdfData.grazingTerm, fresnelIridescent);
    return c;
}
half3 GlobalIlluminationIridescence(BRDFData brdfData, half iridescenceThickness, half iridescenceEta2, half iridescenceEta3, half iridescenceKappa3, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

    float3 halfDir = SafeNormalize(float3(reflectVector)+float3(viewDirectionWS));
    float cosTheta1 = dot(halfDir, float3(reflectVector));

    half3 fresnelIridescent = ThinFilmIridescence(iridescenceEta2, iridescenceEta3, iridescenceKappa3, iridescenceThickness, cosTheta1);
    fresnelIridescent += fresnelTerm.rrr;
    return EnvironmentBRDFIridescence(brdfData, indirectDiffuse, indirectSpecular, fresnelIridescent);
}
half4 URPFragmentPBRIridescence(InputData inputData, half iridescenceThickness, half iridescenceEta2, half iridescenceEta3, half iridescenceKappa3, half3 albedo, half metallic,
    half smoothness, half occlusion, half3 emission, half alpha) {
    BRDFData brdfData;
    InitializeBRDFData_URP(albedo, metallic, smoothness, alpha, brdfData);
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 GI = GlobalIlluminationIridescence(brdfData, iridescenceThickness, iridescenceEta2, iridescenceEta3, iridescenceKappa3, inputData.bakedGI, occlusion, inputData.normalWS,
        inputData.viewDirectionWS);

    half3 DirectBDRF = LightingPhysicallyBasedIridescence(brdfData, iridescenceThickness, iridescenceEta2, iridescenceEta3, iridescenceKappa3, mainLight, inputData.normalWS, inputData.viewDirectionWS);
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
