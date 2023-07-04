#ifndef URP_GRASS_PASS_INCLUDED
#define URP_GRASS_PASS_INCLUDED

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
    half4 normalWSAndCamDistance : TEXCOORD2;

    half fogFactor : TEXCOORD3;
    float4 shadowCoord : TEXCOORD4;
#if defined(_SCATTERING)
    half3 viewDirWS : TEXCOORD5;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitVert(Attributes input) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    
    half3 oriPositionWS = TransformObjectToWorld(input.positionOS.xyz);
    
#if defined(UNITY_ANY_INSTANCING_ENABLED)
    half offset = sin((_Time.y + input.positionOS.x + input.positionOS.z) * _Speed) * max(0, input.positionOS.y - 0.2) * _Range;
    input.positionOS += half4(offset, 0, offset, 0);
#endif

    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    
    half4 positionCS = TransformWorldToHClip(positionWS);

    half3 cameraPos = GetCameraPositionWS();
    half3 viewDirWS = GetCameraPositionWS() - positionWS;
    output.normalWSAndCamDistance.xyz = normalWS;
    output.normalWSAndCamDistance.w = distance(positionWS, cameraPos);
    output.positionCS = positionCS;
    output.shadowCoord  = float4(0, 0, 0, 0);
    
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#else
    output.shadowCoord.xyz = positionWS;
#endif
    
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(normalWS.xyz, output.vertexSH);

    half3 vertexLight = VertexLighting(positionWS, normalWS);
    output.fogFactor = ComputeFogFactor(positionCS.z);

#if defined(_SCATTERING)
    output.viewDirWS = viewDirWS;
#endif


    return output;
}

#include "ShaderLibrary/Sampling.hlsl"
half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    half3 albedo;
    half occlusion;
    half alpha;

    SampleBaseMapOnly(input.uv, /*out*/ albedo, /*out*/ occlusion, /*out*/ alpha);
    alpha -= step(_CameraDistance, input.normalWSAndCamDistance.w);
    AlphaDiscard(alpha);
    half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWSAndCamDistance.xyz);

    half4 shadowCoord = 0;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
#endif

    half4 color = 1;
    half3 sss = 0;
#if defined(_SCATTERING)
    sss = TreeSSS(input.normalWSAndCamDistance.xyz, input.viewDirWS,
                        _MainLightPosition.xyz, _SubsurfaceColor);
#endif
    color.rgb = Lambert(albedo, input.normalWSAndCamDistance.xyz, shadowCoord, bakedGI, sss);
    color.a = alpha;
    return color;
}


half4 LitFragNoClip(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    half3 albedo;
    half occlusion;
    half alpha;

    SampleBaseMapOnly(input.uv, /*out*/ albedo, /*out*/ occlusion, /*out*/ alpha);
    // alpha -= step(_CameraDistance, input.normalWSAndCamDistance.w);
    // AlphaDiscard(alpha);
    half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWSAndCamDistance.xyz);
    half4 shadowCoord = 0;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
#endif

    half4 color = 1;
    half3 sss = 0;
#if defined(_SCATTERING)
    sss = TreeSSS(input.normalWSAndCamDistance.xyz, input.viewDirWS,
                        _MainLightPosition.xyz, _SubsurfaceColor);
#endif
    color.rgb = Lambert(albedo, input.normalWSAndCamDistance.xyz, shadowCoord, bakedGI, sss);
    color.a = alpha;

    return color;
}

#endif //URP_GRASS_PASS_INCLUDED
