#ifndef URP_CLOTH_LIT_PASS_INCLUDED
#define URP_CLOTH_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting.hlsl"

struct AdditionalData {
    half3 tangentWS;
    half3 bitangentWS;

    float partLambdaV;

    half roughnessT;
    half roughnessB;

    half3 anisoReflectionNormal;
    half3 sheenColor;
};

half3 DirectBDRF_Cloth(BRDFData brdfData, AdditionalData addData, half3 normalWS, half3 lightDirectionWS,
                       half3 viewDirectionWS, half NdotL) {
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    half NdotV = saturate(dot(normalWS, viewDirectionWS));

#if defined(_COTTONWOOL)
        //  NOTE: We use the noPI version here!!!!!!
        float D = D_CharlieNoPI(NoH, brdfData.roughness);
        //  Unity: V_Charlie is expensive, use approx with V_Ashikhmin instead
        //  Unity: float Vis = V_Charlie(NdotL, NdotV, bsdfData.roughness);
        float Vis = V_Ashikhmin(NdotL, NdotV);

        //  Unity: Fabrics are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
    //  Unity: We don't use Fresnel term for CharlieD
    //  SheenColor seemed way too dark (compared to HDRP) – so i multiply it with PI which looked ok and somehow matched HDRP
        //  Therefore we use the noPI charlie version. As PI is a constant factor the artists can tweak the look by adjusting the sheen color.
        float3 F = addData.sheenColor; // * PI;
        half3 specularLighting = F * Vis * D;

        //  Unity: Note: diffuseLighting originally is multiply by color in PostEvaluateBSDF
    //  So we do it here :)
        //  Using saturate to get rid of artifacts around the borders.
        return saturate(specularLighting) + brdfData.diffuse * FabricLambert(brdfData.roughness);
#else

    float TdotH = dot(addData.tangentWS, halfDir);
    float TdotL = dot(addData.tangentWS, lightDirectionWS);
    float BdotH = dot(addData.bitangentWS, halfDir);
    float BdotL = dot(addData.bitangentWS, lightDirectionWS);

    float3 F = F_Schlick(brdfData.specular, LoH);

    //float TdotV = dot(addData.tangentWS, viewDirectionWS);
    //float BdotV = dot(addData.bitangentWS, viewDirectionWS);

    float DV = DV_SmithJointGGXAniso(
        TdotH, BdotH, NoH, NdotV, TdotL, BdotL, NdotL,
        addData.roughnessT, addData.roughnessB, addData.partLambdaV
    );
    // Check NdotL gets factores in outside as well.. correct?
    half3 specularLighting = F * DV;

    return specularLighting + brdfData.diffuse;
#endif

    //half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    //return color;
#else
    return brdfData.diffuse;
#endif
}

half3 LightingPhysicallyBased_Cloth(BRDFData brdfData, AdditionalData addData, half3 lightColor, half3 lightDirectionWS,
                                    half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL) {
    //half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBDRF_Cloth(brdfData, addData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance;
}

half3 LightingPhysicallyBased_Cloth(BRDFData brdfData, AdditionalData addData, Light light, half3 normalWS,
                                    half3 viewDirectionWS, half NdotL) {
    return LightingPhysicallyBased_Cloth(brdfData, addData, light.color, light.direction,
                                         light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS,
                                         NdotL);
}

half4 ClothFragmentPBR(InputData inputData, half3 albedo, half3 specular,
                       half smoothness, half occlusion, half3 emission, half alpha, half3 tangentWS, half3 bitangentWS,
                       half anisotropy, half3 sheenColor, half translucency) {

#if defined(_COTTONWOOL)
        smoothness = lerp(0.0h, 0.6h, smoothness);
#endif

    BRDFData brdfData;
    InitializeBRDFData(albedo, 0, specular, smoothness, alpha, brdfData);

    //  Do not apply energy conservtion
    brdfData.diffuse = albedo;
    brdfData.specular = specular;

    AdditionalData addData;
    //  The missing bits - checked with per vertex bitangent and tangent    
    addData.bitangentWS = normalize(-cross(inputData.normalWS, tangentWS)); //bitangentWS;
    //  We can get away with a single normalize here
    addData.tangentWS = cross(inputData.normalWS, addData.bitangentWS); // tangentWS;

    //  We do not apply ClampRoughnessForAnalyticalLights here
    addData.roughnessT = brdfData.roughness * (1 + anisotropy);
    addData.roughnessB = brdfData.roughness * (1 - anisotropy);

#if !defined(_COTTONWOOL)
    float TdotV = dot(addData.tangentWS, inputData.viewDirectionWS);
    float BdotV = dot(addData.bitangentWS, inputData.viewDirectionWS);
    float NdotV = dot(inputData.normalWS, inputData.viewDirectionWS);
    addData.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, addData.roughnessT, addData.roughnessB);

    //  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
    half3 grainDirWS = (anisotropy >= 0.0) ? bitangentWS : tangentWS;
    half stretch = abs(anisotropy) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
    addData.anisoReflectionNormal = GetAnisotropicModifiedNormal_URP(grainDirWS, inputData.normalWS,
                                                                 inputData.viewDirectionWS, stretch);
    half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(anisotropy));

    //  Overwrite perceptual roughness for ambient specular reflections
    brdfData.perceptualRoughness = iblPerceptualRoughness;
#else
        //  partLambdaV should be 0.0f in case of cotton wool
        addData.partLambdaV = 0.0h;
        addData.anisoReflectionNormal = inputData.normalWS;

        float NdotV = dot(inputData.normalWS, inputData.viewDirectionWS);

    //  Only used for reflections - so we skip it
    /*float3 preFGD = SAMPLE_TEXTURE2D_LOD(_PreIntegratedLUT, sampler_PreIntegratedLUT, float2(NdotV, brdfData.perceptualRoughness), 0).xyz;
    // Denormalize the value
    preFGD.y = preFGD.y / (1 - preFGD.y);
    half3 specularFGD = preFGD.yyy * fresnel0;
    // z = FabricLambert
    half3 diffuseFGD = preFGD.z;
    half reflectivity = preFGD.y;*/
#endif
    addData.sheenColor = sheenColor;

    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, addData.anisoReflectionNormal,
                                     inputData.viewDirectionWS);
    color += LightingPhysicallyBased_Cloth(brdfData, addData, mainLight, inputData.normalWS, inputData.viewDirectionWS,
                                           NdotL);
    color += SSS(NdotL, mainLight, inputData.normalWS, inputData.viewDirectionWS, translucency, brdfData.diffuse) * 4;

#ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            Light light = GetAdditionalLight(i, inputData.positionWS);
            NdotL = saturate(dot(inputData.normalWS, light.direction ));
            color += LightingPhysicallyBased_Cloth(brdfData, addData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
            //  translucency
            color += SSS(NdotL, mainLight, inputData.normalWS, inputData.viewDirectionWS , translucency, brdfData.diffuse) * 4;
        }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += emission;
    return half4(color, alpha);
}

half4 LitFrag(Varyings input
#ifdef _VFACE
 , half facing : VFACE
#endif
) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    //  Get the surface description
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv.xy, surfaceData);

    //  Prepare surface data (like bring normal into world space and get missing inputs like gi
    InputData inputData;
    
#ifdef _VFACE
    InitializeInputData(input, surfaceData.normalTS, facing, inputData);
#else
    InitializeInputData(input, surfaceData.normalTS, inputData);
#endif

    //  Apply lighting
    half4 color = ClothFragmentPBR(
        inputData,
        surfaceData.albedo,
        surfaceData.specular,
        surfaceData.smoothness,
        surfaceData.occlusion,
        surfaceData.emission,
        surfaceData.alpha,
        //  #if !defined(_COTTONWOOL) &&  defined(_NORMALMAP)
#if !defined(_COTTONWOOL) &&  defined(_NORMALMAP)
            input.tangentWS.xyz,
            input.bitangentWS.xyz,
#else
        half3(0.1, 0, 0),
        half3(0, 0, 0.1),
#endif
        _Anisotropy,
        _SheenColor,
#if defined(_SCATTERING)
            surfaceData.translucency
#else
        0
#endif
    );

    //  Add fog
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif //URP_SKIN_LIT_PASS_INCLUDED
