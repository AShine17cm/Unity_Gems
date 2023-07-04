#ifndef URP_DEPTH_ONLY_PASS_INCLUDED
#define URP_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "ShaderLibrary/BaseSampling.hlsl"

struct Attributes
{
    float4 position     : POSITION;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);

    #ifdef _CUTOFF_OR_TRANSUV
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    #else
    output.uv = input.texcoord;
    #endif
    
    output.positionCS = TransformObjectToHClip(input.position.xyz);
    return output;
}

half4 DepthOnlyFragment(Varyings input) : SV_TARGET
{
    #ifdef _CUTOFF_OR_TRANSUV
    AlphaDiscard(input.uv);
    #endif
    
    return 0;
}

half4 DepthOnlyFragmentOpaque(Varyings input) : SV_TARGET
{
    return 0;
}
#endif
