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
    float4 lambertAndFogFactor : TEXCOORD1;
    float4 positionCS : SV_POSITION;

#ifdef LIGHTMAP_ON
        float2 lightmapUV               : TEXCOORD2;
#endif

#if defined(_MATCAP)
    float3 normalVS                 : TEXCOORD3;
#endif
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
    half4 shadowCoord = TransformWorldToShadowCoord(positionWS);

    half3 bakedGI = 0;
#ifdef LIGHTMAP_ON
    output.lightmapUV = input.lightmapUV;
#else
    bakedGI = SampleSHVertex_Test(normalWS);
#endif

#if defined(_MATCAP)
    output.normalVS = TransformWorldToViewDir(normalWS) * 0.5 + 0.5;
#endif


    output.lambertAndFogFactor.rgb = Lambert(1, normalWS, positionWS, shadowCoord, bakedGI, 0);
    output.positionCS = positionCS;
    output.lambertAndFogFactor.a = ComputeFogFactor(positionCS.z);
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
    AlphaDiscard(alpha);

    half emissionMask = 1;
    half3 emission = SampleEmissionMask(uv, emissionMask);
    albedo = LerpPattern(uv, saturate(alpha * (1 - emissionMask)), albedo);

#if defined(_MATCAP)
    half3 matcap = 1;
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif

    half4 color = VertexLitLighting(input.lambertAndFogFactor, albedo, emission, occlusion, alpha
#ifdef LIGHTMAP_ON
        ,input.lightmapUV
#else
    ,0
#endif
#if defined(_MATCAP)
        ,matcap
#endif
    );
    return color;
}

#endif //URP_VERTEXLIT_PASS_INCLUDED
