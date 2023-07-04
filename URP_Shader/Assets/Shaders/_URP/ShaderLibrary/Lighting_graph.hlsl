#ifndef URP_LIGHTING_INCLUDED
#define URP_LIGHTING_INCLUDED

void Specular_float(float3 positionWS, float3 normalWS, float3 viewDirWS, float roughness, out float3 Specular)
{
    #if SHADERGRAPH_PREVIEW
        Specular = 0;
    #else
        Light mainLight = GetMainLight();
        float3 L = normalize(mainLight.direction);
        float3 N = normalize(normalWS);
        float3 V = normalize(viewDirWS);
        float3 H = SafeNormalize(L + V);

        roughness = roughness / 250;

        float Roughness2 = roughness * roughness;
        float NdotH = saturate(dot(N, H)); 
        float LdotH = saturate(dot(L, H));
        
        float d = NdotH * NdotH * (Roughness2 - 1.h) + 1.0001h;
        float LdotH2 = LdotH * LdotH;
        
        float specularTerm = Roughness2 / ((d * d) * max(0.1h, LdotH2) * (roughness + 0.5h) * 4);
        #if defined (SHADER_API_MOBILE)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 5.0); 
        #endif
        Specular = specularTerm * mainLight.color * mainLight.distanceAttenuation;
    #endif
}

inline half MainLightRealtimeShadow_Graph(float4 shadowCoord) {
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
}

inline Light GetMainLight_Graph(float4 shadowCoord) {
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightRealtimeShadow_Graph(shadowCoord);
    return light;
}


void Lambert_float(float3 positionWS, float3 normalWS,  out float3 DiffuseColor){
    #if SHADERGRAPH_PREVIEW
        DiffuseColor = 0.5;
    #else
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
        Light mainLight = GetMainLight_Graph(shadowCoord);
        // Light mainLight = GetMainLight();
        float3 L = normalize(mainLight.direction);
        float3 N = normalize(normalWS);
        half3 attenuatedLightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
        DiffuseColor = saturate(dot(N, L)) * attenuatedLightColor;
    #endif  
}

void BlinnPhong_float(float3 positionWS, float3 normalWS, float3 viewDirWS, float3 specular, float smoothness,  out float3 SpecularColor){
   #if SHADERGRAPH_PREVIEW
       SpecularColor = 0.5;
   #else
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
        Light mainLight = GetMainLight_Graph(shadowCoord);
        half3 attenuatedLightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    
        float3 H = SafeNormalize(float3(mainLight.direction) + float3(viewDirWS));
        half NdotH = saturate(dot(normalWS, H));
        half3 specularReflection = specular.rgb *  pow(NdotH, smoothness);
        SpecularColor = attenuatedLightColor * specularReflection;
    #endif  
}
#endif //URP_LIGHTING_INCLUDED