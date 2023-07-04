#ifndef URP_BILLBOARD_PASS_INCLUDED
#define URP_BILLBOARD_PASS_INCLUDED


#include "ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 lambertAndFogFactor      : TEXCOORD1;
    float4 positionCS               : SV_POSITION;
#ifdef LIGHTMAP_ON
        float2 lightmapUV               : TEXCOORD2;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

void billboard(inout float4 positionOS, out float3 normalOS)
{
    float3 local = float3(positionOS.xy, 0);
    float3 offset = positionOS.xyz - local;
    half3 upVector = half3(0, 1, 0);
    half3 forwardVector = UNITY_MATRIX_IT_MV[2].xyz;
    half3 rightVector = normalize(cross(forwardVector, upVector));
    float3 position = 0;
    position += local.x * rightVector;
    position += local.y * upVector;
    position.z += positionOS.z;
    positionOS = float4(position, 1);
    normalOS = forwardVector;
}


Varyings LitVert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    billboard(input.positionOS, input.normalOS);
    
    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    half4 positionCS = TransformWorldToHClip(positionWS);
    
    half4 shadowCoord = float4(0, 0, 0, 0);
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        shadowCoord = TransformWorldToShadowCoord(positionWS);
    #endif
    
    half3 bakedGI = 0;
    #ifdef LIGHTMAP_ON
    output.lightmapUV = input.lightmapUV;
    #else
    bakedGI = SampleSHVertex(normalWS);
    #endif
    
    output.positionCS = positionCS;
    
    output.lambertAndFogFactor.rgb = Lambert(1, normalWS, positionWS, shadowCoord, bakedGI, 0);
    output.lambertAndFogFactor.a = ComputeFogFactor(positionCS.z);
    return output;
}

#include "ShaderLibrary/Sampling.hlsl"

half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    half3 albedo;
    half occlusion;
    half alpha;
    
    SampleBaseMapOnly(input.uv, /*out*/ albedo, /*out*/ occlusion, /*out*/ alpha);
    AlphaDiscard(alpha);
    
    // bakedGI = SampleLightmap(lightmapUV, normalWS);
    
    half4 color = VertexLitLighting(input.lambertAndFogFactor, albedo, 0, occlusion, alpha
#ifdef LIGHTMAP_ON
        ,input.lightmapUV
#endif
    );

    return color;
}

#endif //URP_BILLBOARD_PASS_INCLUDED