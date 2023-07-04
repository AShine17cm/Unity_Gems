#ifndef URP_DATA_INPUT_INCLUDED
#define URP_DATA_INPUT_INCLUDED

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
    float2 uv : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)  || defined(_NEED_POS_WS)
    float3 positionWS               : TEXCOORD2;
#endif
#if defined (_NORMALMAP)
    float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    float3 normalWS : TEXCOORD3;
    float3 viewDirWS : TEXCOORD4;
#endif

    half4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light\
  

 #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord                    : TEXCOORD7;
 #endif

    float3 positionOS                     : TEXCOORD8;

    float4 positionCS : SV_POSITION;


#ifdef _VCOLOR
    half4 color                     : COLOR;
#endif


    float4 screenPos    : TEXCOORD9;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "ShaderLibrary/InputData.hlsl"

VertexPositionInputs GetVertexPositionInputs_Offset(float3 positionOS, float3 offset) {
    VertexPositionInputs input;
    input.positionWS = TransformObjectToWorld(positionOS);
    input.positionWS += offset;
    input.positionVS = TransformWorldToView(input.positionWS);
    input.positionCS = TransformWorldToHClip(input.positionWS);

    float4 ndc = input.positionCS * 0.5f;
    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    input.positionNDC.zw = input.positionCS.zw;

    return input;
}
half3x3 CreateTangentToWorldPerVertex(half3 normal, half3 tangent, half tangentSign)
{
    // For odd-negative scale transforms we need to flip the sign
    half sign = tangentSign * unity_WorldTransformParams.w;
    half3 binormal = cross(normal, tangent) * sign;
    return half3x3(tangent, binormal, normal);
}

Varyings LitVert(Attributes input,half _FUR_OFFSET = 0) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.uv = input.texcoord;

    half3 direction = lerp(input.normalOS, _Gravity * _GravityStrength + input.normalOS * (1 - _GravityStrength), FUR_OFFSET);

	input.positionOS.xyz += direction * _FurLength * FUR_OFFSET;

    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

#if  defined(_NORMALMAP)
    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
    output.viewDirWS = viewDirWS;
#endif

    output.positionOS = input.positionOS.xyz;



    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR) || defined(_NEED_POS_WS)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

#ifdef _VCOLOR
    output.color = input.color;
#endif

output.screenPos=ComputeScreenPos(output.positionCS);

    return output;
}
#endif //URP_DATA_INPUT_INCLUDED
