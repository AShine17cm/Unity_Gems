#ifndef URP_VERTEXLIT_PASS_INCLUDED
#define URP_VERTEXLIT_PASS_INCLUDED

#include "ShaderLibrary/Lighting.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
    half3 normalWS : TEXCOORD2;

#if defined(_MATCAP)
    float3 normalVS                 : TEXCOORD3;
#endif

    half fogFactor : TEXCOORD4;
    float4 shadowCoord : TEXCOORD5;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitVert(Attributes input) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    half4 positionCS = TransformWorldToHClip(positionWS);

#if defined(_MATCAP)
    output.normalVS = TransformWorldToViewDir(normalWS) * 0.5 + 0.5;
#endif

    output.positionCS = positionCS;
    output.normalWS = normalWS;
    
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#else
    output.shadowCoord.xyz = positionWS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    half3 vertexLight = VertexLighting(positionWS, normalWS);
    output.fogFactor = ComputeFogFactor(positionCS.z);
    return output;
}


#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Sampling.hlsl"


half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    float2 uv = input.uv;

    half3 albedo;
    half occlusion;
    half alpha;
    SampleBaseMap(uv, albedo, occlusion, alpha);
#if defined(_PATTERNMAP)
    alpha = 1;
#endif
    AlphaDiscard(alpha);


    half emissionMask = 1;
    half3 emission = SampleEmissionMask(uv, emissionMask);
    
    albedo = LerpPattern(uv, saturate(alpha * (1 - emissionMask)), albedo);
    half3 matcap = 1;
#if defined(_MATCAP)
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif

    half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);

    half4 shadowCoord = 0;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
#endif

    half4 color = 1;
    color.rgb = Lambert(albedo, input.normalWS, shadowCoord, bakedGI, emission);
    color.rgb *= matcap;
    color.rgb = MixFog(color.rgb, input.fogFactor);
    color.a = alpha;
#ifdef _EMISSION
#ifdef _HairGradient
    float2 uvGradientTex = TRANSFORM_TEX(input.positionWS.xy, _GradientMap);
    float2 uvGradient = float2(_Gradient_U_Speed, _Gradient_V_Speed) * _Time.y + uvGradientTex;
    float4 Gradient = SAMPLE_TEXTURE2D(_GradientMap, sampler_GradientMap, uvGradient);
    float4 mask = lerp(float4(0, 0, 0, 0), float4(1, 1, 1, 1), (2 - input.positionWS.y / _Fill)) * _Intensity;
    mask = mask.a > 0 ? mask : 0;
    float4 finalcol = Gradient * mask;
    finalcol *= _GradientColor;
    float4 fill = step((2 - input.positionWS.y / _Fill), 1);
    finalcol *= fill;
    color.rgb += finalcol.rgb;
#endif  
#endif 
    return color;
}

half4 LitFragSkin(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    float2 uv = input.uv;

    half3 albedo;
    half occlusion;
    half alpha;
    SampleBaseMap(uv, albedo, occlusion, alpha);
#if defined(_PATTERNMAP)
    alpha = 1;
#endif

    AlphaDiscard(alpha);
    half emissionMask = 1;
    half3 emission = SampleEmissionMask(uv, emissionMask);
    
    albedo = LerpPattern(uv, saturate(alpha * (1 - emissionMask)), albedo);
#if defined(_ENABLESKIN)
 float3 albedo1=lerp(albedo,albedo/_addSkinColor,step(emission.g,0.4980391f));
#endif

    half3 matcap = 1;
#if defined(_MATCAP)
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif

    half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);
    half4 shadowCoord = 0;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
#endif

    half4 color = 1;
#if defined(_ENABLESKIN)
    color.rgb = Lambert(albedo1/**1.2*/, input.normalWS, shadowCoord, bakedGI, emission);
#else
    color.rgb = Lambert(albedo, input.normalWS, shadowCoord, bakedGI, emission);
#endif
    color.rgb *= matcap;
    color.rgb = MixFog(color.rgb, input.fogFactor);
    color.a = alpha;

    return color;
}
#endif //URP_VERTEXLIT_PASS_INCLUDED
