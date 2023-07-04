#ifndef AURORA_ANISO
#define AURORA_ANISO
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "../pbr/common/vert.hlsl"
half _Brightness;
half _Gloss;
half _AmbientBrightnessAniso;

fixed4 _SpecularColor;
half _SpecularBrightness;

half _AnisoOffset;
half4 _AnisoDirection;

fixed4 _SpecularBrightness2;
fixed4 _SpecularColor2;

inline half3 LightingAnisotropic (float3 wPos, float3 wNormal, half3 albedoColor, half gloss)
{
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - wPos);
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    float3 lightColor = _LightColor0.rgb * _LightBrightness;
    float3 halfDir = normalize(viewDirection + lightDir);

    float atten = LIGHT_ATTENUATION(i);
    half3 attenColor = _LightColor0.rgb * _Brightness * atten;

    half NdotL = saturate(dot(wNormal, lightDir));
    half HdotA = dot(normalize(wNormal + _AnisoDirection), halfDir); 
    half aniso = max(0, sin(radians(HdotA * 180 + _AnisoOffset)));
    half3 diff = max(0, NdotL ) * attenColor + _AmbientBrightnessAniso * UNITY_LIGHTMODEL_AMBIENT.rgb;

    half specPow = exp2( _Gloss * 10.0 + 1.0 );
    half spec = saturate(pow (aniso, specPow) * gloss * attenColor * _SpecularBrightness);
    
    float4 c;
    float3 ColorOne = float3(1, 1, 1);
    half3 albedo = albedoColor * (ColorOne + (_SpecularColor2 - ColorOne) * gloss) + _SpecularBrightness2 * gloss;
    albedo = saturate(albedo);
    return albedo * diff + spec * _SpecularColor.rgb;
}

inline half3 LightingAnisotropicRawNormal (VertexPBROutput i, half3 albedoColor, float2 rawNormalColor, half gloss)
{
    float3 normalLocal = float3(rawNormalColor.r, rawNormalColor.g, 1) * 2 - 1; // TODO DO NOT mark the texture as "Normal map", and use the built-in function? Can't get the right ba?
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
    return LightingAnisotropic(i.posWorld.xyz, normalDirection, albedoColor, gloss);   
}
#endif // AURORA_ANISO