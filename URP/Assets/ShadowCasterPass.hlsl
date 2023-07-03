#ifndef UNIVERSAL_MG_SHADOW_CASTER_PASS_INCLUDED
#define UNIVERSAL_MG_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

#include "ShaderLibrary/BaseSampling.hlsl"

float3 _LightDirection;

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
#ifdef _SHADOW_OFFSET
    UNITY_VERTEX_INPUT_INSTANCE_ID
#endif
};

float4 GetShadowPositionHClip(Attributes input) {
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input) {
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

#ifdef _SHADOW_OFFSET

    #if defined(_ALPHATEST_ON) && defined(_MASKMAP)
            output.uv.xy = TRANSFORM_TEX(input.texcoord, _MaskMap);
    #endif

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldDir(input.normalOS);

    output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS * _ShadowOffset, _LightDirection));
    #if UNITY_REVERSED_Z
            output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
            output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

#else
    #ifdef _CUTOFF_OR_TRANSUV
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    #else
    output.uv = input.texcoord;
    #endif
    
    output.positionCS = GetShadowPositionHClip(input);
#endif

    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET {
    #if defined(_CUTOFF_OR_TRANSUV) & defined(_ALPHATEST_ON)
    float alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
    clip(alpha - _Cutoff);
    #endif
    return 0;
}
#endif //UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
