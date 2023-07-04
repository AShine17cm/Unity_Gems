#ifndef URP_GRASS_PASS_INCLUDED
#define URP_GRASS_PASS_INCLUDED

#include "ShaderLibrary/Lighting.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    float cameraDistance : TEXCOORD2;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitVert(Attributes input) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
#if defined(UNITY_ANY_INSTANCING_ENABLED)
    half offset = sin((_Time.y + input.positionOS.x + input.positionOS.z) * _Speed) * max(0, input.positionOS.y - 0.2) * _Range;
    input.positionOS += half4(offset, 0, offset, 0);
#endif

    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half4 positionCS = TransformWorldToHClip(positionWS);
    
    half3 cameraPos = GetCameraPositionWS();
    half3 viewDirWS = GetCameraPositionWS() - positionWS;
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.cameraDistance = distance(positionWS, cameraPos);
    output.positionCS = positionCS;
    return output;
}

Varyings LitVertStatic(Attributes input) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half4 positionCS = TransformWorldToHClip(positionWS);
    
    half3 cameraPos = GetCameraPositionWS();
    half3 viewDirWS = GetCameraPositionWS() - positionWS;
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.cameraDistance = distance(positionWS, cameraPos);
    output.positionCS = positionCS;
    return output;
}

#include "ShaderLibrary/Sampling.hlsl"
half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    half3 albedo;
    half occlusion;
    half alpha;

    SampleBaseMapOnly(input.uv, /*out*/ albedo, /*out*/ occlusion, /*out*/ alpha);
    alpha -= step(_CameraDistance, input.cameraDistance);
    AlphaDiscard(alpha);
    return 1;
}

#endif //URP_GRASS_PASS_INCLUDED
