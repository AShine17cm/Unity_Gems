#ifndef URP_ROCK_DATA_INCLUDE
#define URP_ROCK_DATA_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
#ifdef _VCOLOR
 half4 color         : COLOR;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 0);

    float3 positionWS : TEXCOORD1;

    float3 normalWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD3;

    half4 fogFactorAndVertexLight : TEXCOORD4; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD5;
#endif

    float4 positionCS : SV_POSITION;
#ifdef _VCOLOR
    half4 color                     : TEXCOORD6;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#endif //URP_ROCK_DATA_INCLUDE
